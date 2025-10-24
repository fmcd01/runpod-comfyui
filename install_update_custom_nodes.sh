#!/bin/bash
set -e  # Exit the script if any statement returns a non-true return value

COMFYUI_DIR=/workspace/ComfyUI


# Ensure that custome nodes directory exists
mkdir -p $COMFYUI_DIR/custom_nodes

# Install additional custom nodes from Git repos
# 	"https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
CUSTOM_NODES=(
	"https://github.com/ltdrdata/ComfyUI-Manager"
	"https://github.com/kijai/ComfyUI-KJNodes"
	"https://github.com/rgthree/rgthree-comfy"
	"https://github.com/yolain/ComfyUI-Easy-Use"
	"https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
	"https://github.com/HECer/ComfyUI-FilePathCreator"
	"https://github.com/SLAPaper/ComfyUI-Image-Selector"
	"https://github.com/SquirrelRat/MultiString-Prompts"
	"https://github.com/cubiq/ComfyUI_essentials"
	"https://github.com/Fannovel16/ComfyUI-Frame-Interpolation"
)

for repo in "${CUSTOM_NODES[@]}"; do
	repo_name=$(basename "$repo")
	echo "Check status for repo: $repo_name, in $COMFYUI_DIR/custom_nodes/$repo_name"
        if [ ! -d "$COMFYUI_DIR/custom_nodes/$repo_name" ]; then
            echo "Installing $repo_name..."
            cd "$COMFYUI_DIR/custom_nodes"
            git clone "$repo"
	else
		echo "Upgrading $repo_name..."
		cd "$COMFYUI_DIR/custom_nodes/$repo_name"
		git pull
        fi
done


# Enable venv
echo "Enable venv..."
cd $COMFYUI_DIR
source venv/bin/activate

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

# Update Comfy
cd "$COMFYUI_DIR"
pip install --no-cache -r requirements.txt

find $COMFYUI_DIR -type d -name "__pycache__" -exec rm -rf {} +