#!/bin/bash

# Update system packages
apt update && apt upgrade -y

# Install software-properties-common to add PPA
apt install -y software-properties-common

# Add deadsnakes PPA for Python 3.12
#add-apt-repository ppa:deadsnakes/ppa -y
#apt update

# Install Python 3.12 and required dependencies, including build tools for sentencepiece
apt install -y python3.12 python3.12-venv python3.12-dev git python3-pip wget cmake pkg-config

# Set Python 3.12 as the default python3
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
update-alternatives --set python3 /usr/bin/python3.12

# Verify Python version
echo "System Python version: $(python3 --version)"

# Stop and disable Nginx if it's running
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
pkill -f nginx || true

# Set up workspace
mkdir -p /workspace && cd /workspace

# Clone and install ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Create an isolated virtual environment with Python 3.12
python3.12 -m venv venv
source venv/bin/activate

# Verify virtual environment Python version
echo "Virtual environment Python version: $(python --version)"

# Upgrade pip in the virtual environment
pip install --upgrade pip

# Install PyTorch 2.7.0 with CUDA 12.8 support in the venv
pip install torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu128

# Verify PyTorch installation
echo "Using venv PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "Venv PyTorch CUDA version: $(python -c 'import torch; print(torch.version.cuda)')"

# Install remaining ComfyUI dependencies in the venv
pip install -r requirements.txt

# Clone and install ComfyUI-Manager inside custom_nodes
mkdir -p custom_nodes
cd custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
cd ComfyUI-Manager
pip install -r requirements.txt

# Set execution permission
chmod +x /workspace/ComfyUI/main.py

# Kill any process using port 3001
fuser -k 8188/tcp || true

exit 

# Run ComfyUI on port 8188
cd /workspace/ComfyUI
source venv/bin/activate
python main.py --listen --port 8188
