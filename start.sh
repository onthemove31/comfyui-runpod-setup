#!/bin/bash

echo "🚀 Starting Custom ComfyUI Container..."

# 1. Activate Virtual Environment (Updated Path)
source /root/comfyui/ComfyUI/.venv/bin/activate

# 2. Wait for Internet
echo "📶 Waiting for network..."
until curl -s https://github.com > /dev/null; do sleep 2; done

# 3. VS Code Tunnel
echo "🛠️  Setting up VS Code Tunnel..."
export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1
curl -sL 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output /tmp/vscode_cli.tar.gz
tar -xf /tmp/vscode_cli.tar.gz -C /usr/bin

echo "----------------------------------------------------------------"
echo "🔗 AUTHENTICATION REQUIRED: Check logs for code!"
echo "----------------------------------------------------------------"
/usr/bin/code tunnel --accept-server-license-terms --name runpod-gpu --provider microsoft &

# 4. Handle ComfyUI Manager Security (Updated Path)
MANAGER_CONFIG="/root/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    echo "🔒 Enforcing Normal Security for ComfyUI Manager..."
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

# 5. Start ComfyUI (Updated Path)
echo "🎨 Starting ComfyUI..."
cd /root/comfyui/ComfyUI
python main.py --listen 0.0.0.0 --port 8188