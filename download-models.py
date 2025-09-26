import os, sys, yaml, subprocess

model_type = os.environ.get("MODEL_TYPE", "flux1-dev-fp8")
token = os.environ.get("HUGGINGFACE_ACCESS_TOKEN", "")
home = os.environ.get("RP_WORKSPACE", "")
comfyui = "ComfyUI"
model_dir = f"{home}/{comfyui}/models"

with open("./models.yaml") as f:
    config = yaml.safe_load(f)

# Download common files
for item in config.get("common", []):
    path = f"{model_dir}/{item.get('path', 'clip')}"
    os.makedirs(path, exist_ok=True)
    url = item["url"]
    dest = f"{path}/{item['name']}"
    subprocess.run(["wget", "-q", "-O", dest, url], check=True)

# Download model-specific files
for item in config["models"].get(model_type, []):
    path = f"{model_dir}/{item.get('path','checkpoints')}"
    os.makedirs(path, exist_ok=True)
    url = item["url"]
    dest = f"{path}/{item['name']}"

    cmd = ["wget", "-q", "-O", dest, url]
    if item.get("auth"):
        cmd.insert(1, f"--header=Authorization: Bearer {token}")

    subprocess.run(cmd, check=True)
