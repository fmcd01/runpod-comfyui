import os
import yaml
from huggingface_hub import hf_hub_download
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

# Config
model_type = os.environ.get("MODEL_TYPE", "flux1-dev-fp8")
token = os.environ.get("HUGGINGFACE_ACCESS_TOKEN", None)
home = os.environ.get("RP_WORKSPACE", "")
comfyui = "ComfyUI"
model_dir = os.path.join(home, comfyui, "models")

# Load YAML
with open("./models.yaml") as f:
    config = yaml.safe_load(f)

if model_type not in config["models"]:
    raise ValueError(f"Unknown model_type: {model_type}")

def download_file(item):
    """Download a single file safely with .part temporary file support."""
    path = os.path.join(model_dir, item.get("path", "checkpoints"))
    os.makedirs(path, exist_ok=True)
    dest = os.path.join(path, item["name"])
    tmp_dest = dest + ".part"

    # Skip if already downloaded
    if os.path.exists(dest):
        print(f"{dest} already exists, skipping.")
        return
    # Skip if download in progress
    if os.path.exists(tmp_dest):
        print(f"{tmp_dest} in progress, skipping.")
        return

    url = item["url"]
    use_auth = item.get("auth", False)

    print(f"Downloading {item['name']} ...")

    try:
        if "huggingface.co" in url:
            # Hugging Face URL
            repo_id = url.split("huggingface.co/")[-1].split("/resolve")[0]
            filename = url.split("/")[-1]
            hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                token=token if use_auth else None,
                cache_dir=path,
                local_dir=path,
                local_dir_use_symlinks=False
            )
            # Move to final destination if needed
            file_path = os.path.join(path, filename)
            if file_path != dest:
                os.rename(file_path, dest)
        else:
            # Non-HF URL fallback
            headers = {"Authorization": f"Bearer {token}"} if use_auth else {}
            with requests.get(url, headers=headers, stream=True) as r, open(tmp_dest, "wb") as f:
                r.raise_for_status()
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
            os.rename(tmp_dest, dest)
        print(f"Downloaded {dest} ✅")
    except Exception as e:
        print(f"Error downloading {item['name']}: {e}")
        if os.path.exists(tmp_dest):
            os.remove(tmp_dest)

# Download all files in parallel
items_to_download = config["models"][model_type]

max_workers = min(4, len(items_to_download))  # Adjust for your bandwidth
with ThreadPoolExecutor(max_workers=max_workers) as executor:
    futures = [executor.submit(download_file, item) for item in items_to_download]
    for future in as_completed(futures):
        # Trigger exceptions if any
        future.result()
