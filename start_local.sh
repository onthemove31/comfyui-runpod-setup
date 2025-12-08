#!/bin/bash

echo "🏠 Starting Local ComfyUI (WSL2 Mode)..."

# 1. Activate Virtual Environment
source /root/comfyui/ComfyUI/.venv/bin/activate

# 2. Check for GPU
if ! command -v nvidia-smi &> /dev/null; then
    echo "⚠️  WARNING: nvidia-smi not found. Is your GPU passed correctly?"
else
    echo "✅ GPU Detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
fi

# 3. Handle ComfyUI Manager Security
# For local use, 'normal' is safe.
MANAGER_CONFIG="/root/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    echo "🔒 Enforcing Normal Security for ComfyUI Manager..."
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

# 4. Start ComfyUI
# We listen on 0.0.0.0 so Windows localhost can see it
echo "🎨 Launching ComfyUI..."
echo "👉 Open in Windows: http://localhost:8188"

cd /root/comfyui/ComfyUI
python main.py --listen 0.0.0.0 --port 8188