#!/bin/bash

echo "🏠 Starting Local ComfyUI (WSL2 Mode)..."

# 1. Activate Virtual Environment
source /root/comfyui/ComfyUI/.venv/bin/activate

# 2. Handle ComfyUI Manager Security
# For local use, you might prefer 'weak' or 'normal'.
# Defaulting to normal, but you can change this.
MANAGER_CONFIG="/root/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    echo "🔒 Enforcing Normal Security for ComfyUI Manager..."
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

# 3. Start ComfyUI
# We listen on 0.0.0.0 so Docker exposes it to Windows localhost
echo "🎨 Launching ComfyUI on http://localhost:8188"
cd /root/comfyui/ComfyUI
python main.py --listen 0.0.0.0 --port 8188