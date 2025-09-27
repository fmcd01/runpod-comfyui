import os
import yaml
from huggingface_hub import hf_hub_download
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
import threading

# ----------------- Config -----------------
model_type = os.environ.get("MODEL_TYPE")  # No default
token = os.environ.get("HF_TOKEN", None)
home = os.environ.get("RP_WORKSPACE", "")
comfyui = "ComfyUI"
model_dir = os.path.join(home, comfyui, "models")
max_workers = 1  # adjust based on bandwidth

# ----------------- Load YAML -----------------
with open("./models.yaml") as f:
    config = yaml.safe_load(f)

# ----------------- Collect files to download -----------------
items_to_download = []
if model_type:
    if model_type not in config["models"]:
        raise ValueError(f"Unknown model_type: {model_type}")
    items_to_download.extend(config["models"][model_type])
else:
    # all models
    for model_list in config["models"].values():
        items_to_download.extend(model_list)

# ----------------- Deduplicate by URL + dest -----------------
unique_downloads = {}
for item in items_to_download:
    path = os.path.join(model_dir, item.get("path", "checkpoints"))
    os.makedirs(path, exist_ok=True)
    dest = os.path.join(path, item["name"])
    key = (item["url"], dest)
    unique_downloads[key] = item  # overwrite duplicates safely

# ----------------- Thread-safe locks -----------------
download_locks = {}  # per-dest lock
download_locks_lock = threading.Lock()

def get_file_lock(dest_path):
    with download_locks_lock:
        return download_locks.setdefault(dest_path, threading.Lock())

# ----------------- Download function -----------------
def download_file(item):
    path = os.path.join(model_dir, item.get("path", "checkpoints"))
    os.makedirs(path, exist_ok=True)
    dest = os.path.join(path, item["name"])
    tmp_dest = dest + ".part"

    # Skip if already downloaded
    if os.path.exists(dest):
        print(f"{dest} already exists, skipping.")
        return

    # Acquire per-file lock
    file_lock = get_file_lock(dest)
    with file_lock:
        # Double-check in case another thread finished while waiting
        if os.path.exists(dest):
            print(f"{dest} already downloaded by another thread, skipping.")
            return
        if os.path.exists(tmp_dest):
            print(f"{tmp_dest} in progress, skipping.")
            return

        url = item["url"]
        use_auth = item.get("auth", False)
        print(f"Downloading {item['name']} ...")

        try:
            if "huggingface.co" in url:
                # HF download
                repo_id = url.split("huggingface.co/")[-1].split("/resolve")[0]
                filename = url.split("/resolve/main/")[-1]  # keep subfolders
                hf_hub_download(
                    repo_id=repo_id,
                    filename=filename,
                    token=token if use_auth else None,
                    cache_dir=path,
                    local_dir=path
                )
                file_path = os.path.join(path, os.path.basename(filename))
                if file_path != dest:
                    os.rename(file_path, dest)

            else:
                # Generic URL download
                headers = {"Authorization": f"Bearer {token}"} if use_auth else {}
                with requests.get(url, headers=headers, stream=True) as r, open(tmp_dest, "wb") as f:
                    r.raise_for_status()
                    for chunk in r.iter_content(chunk_size=8192):
                        f.write(chunk)
                os.rename(tmp_dest, dest)

            print(f"Downloaded {dest} ✅")
        except requests.HTTPError as e:
            if e.response.status_code == 403:
                print(f"Skipping {item['name']} (access denied / gated repo).")
            else:
                print(f"Error downloading {item['name']}: {e}")
            if os.path.exists(tmp_dest):
                os.remove(tmp_dest)
        except Exception as e:
            print(f"Error downloading {item['name']}: {e}")
            if os.path.exists(tmp_dest):
                os.remove(tmp_dest)

# ----------------- Parallel download -----------------
with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(download_file, item) for item in unique_downloads.values()]
    for future in as_completed(futures):
        future.result()

print("\nAll downloads complete!")
