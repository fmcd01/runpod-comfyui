# Run ComfyUI on port 8188
cd /workspace/ComfyUI
source venv/bin/activate

source ./install_update_custom_nodes.sh

FIXED_ARGS="--listen 0.0.0.0 --port 8188"
echo "Starting ComfyUI with default arguments"
nohup python main.py $FIXED_ARGS &> /workspace/ComfyUI/comfyui.log &
python main.py --listen --port 8188
