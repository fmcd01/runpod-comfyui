#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

COMFYUI_DIR=/workspace/ComfyUI

# Install additional custom nodes
CUSTOM_NODES=(
	"https://github.com/kijai/ComfyUI-KJNodes"
        "https://github.com/MoonGoblinDev/Civicomfy"
)

for repo in "${CUSTOM_NODES[@]}"; do
	repo_name=$(basename "$repo")
        if [ ! -d "$COMFYUI_DIR/custom_nodes/$repo_name" ]; then
            echo "Installing $repo_name..."
            cd "$COMFYUI_DIR/custom_nodes"
            git clone "$repo"
        fi
done


# Install dependencies for custom nodes
echo "Installing/updating dependencies for custom nodes..."
pip install --no-cache GitPython numpy pillow opencv-python  # Common dependencies


# Install dependencies for all custom nodes
cd "$COMFYUI_DIR/custom_nodes"
for node_dir in */; do
	if [ -d "$node_dir" ]; then
		echo "Checking dependencies for $node_dir..."
		cd "$COMFYUI_DIR/custom_nodes/$node_dir"

		# Check for requirements.txt
		if [ -f "requirements.txt" ]; then
			echo "Installing requirements.txt for $node_dir"
			pip install --no-cache -r requirements.txt
		fi

		# Check for install.py
		if [ -f "install.py" ]; then
			echo "Running install.py for $node_dir"
			python install.py
		fi

		# Check for setup.py
		if [ -f "setup.py" ]; then
			echo "Running setup.py for $node_dir"
			pip install --no-cache -e .
		fi
		cd "$COMFYUI_DIR/custom_nodes" 
	fi
done

