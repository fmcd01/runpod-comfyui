# Run ComfyUI on port 8188

WORKSPACE=/workspace
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

cd $COMFYUI_DIR
source venv/bin/activate

source $WORKSPACE/runpod-comfyui/install_update_custom_nodes.sh

cd $COMFYUI_DIR
FIXED_ARGS="--listen 0.0.0.0 --port 8188"
echo "Starting ComfyUI with default arguments"
nohup python main.py $FIXED_ARGS &> $COMFYUI_DIR/comfyui.log &
python main.py --listen --port 8188
