#!/bin/bash
echo "🚀 Starting SLIM ComfyUI Container..."
source /root/comfyui/ComfyUI/.venv/bin/activate

echo "📶 Waiting for network..."
until curl -s https://github.com > /dev/null; do sleep 2; done

# === HYDRATION STEP ===
if python -c "import torch" &> /dev/null; then
    echo "✅ PyTorch already installed."
else
    echo "⬇️  First Boot: Downloading PyTorch Nightly (cu128)..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    
    cd /root/comfyui/ComfyUI
    pip install -r requirements.txt
    pip install hf_transfer "huggingface_hub[hf_transfer]" comfy-cli opencv-python-headless
    
    echo "📦 Installing Custom Node Requirements..."
    python /install_nodes.py # Runs regular install mode
    pip cache purge
fi
# ======================

# VS Code Tunnel (Same as before)
export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1
curl -sL 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output /tmp/vscode_cli.tar.gz
tar -xf /tmp/vscode_cli.tar.gz -C /usr/bin

echo "----------------------------------------------------------------"
echo "🔗 AUTHENTICATION REQUIRED: Check logs for code"
echo "----------------------------------------------------------------"

/usr/bin/code tunnel user login --provider microsoft
/usr/bin/code tunnel --accept-server-license-terms --name runpod-gpu &

# Security
MANAGER_CONFIG="/root/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

echo "✅ Ready. Run 'python main.py' to start."
sleep infinity