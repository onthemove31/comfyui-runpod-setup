#!/bin/bash

echo "🚀 Starting Custom ComfyUI Container..."

# 1. Wait for Internet
echo "📶 Waiting for network..."
until curl -s https://github.com > /dev/null; do sleep 2; done

# 2. VS Code Tunnel (Stateless Microsoft Mode)
echo "🛠️  Setting up VS Code Tunnel..."
export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1
curl -sL 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output /tmp/vscode_cli.tar.gz
tar -xf /tmp/vscode_cli.tar.gz -C /usr/bin

echo "----------------------------------------------------------------"
echo "🔗 AUTHENTICATION REQUIRED: Check logs for code!"
echo "----------------------------------------------------------------"
# Start Tunnel in Background
/usr/bin/code tunnel --accept-server-license-terms --name runpod-gpu --provider microsoft &

# 3. Handle ComfyUI Manager Security (Runtime Config)
# We set it to NORMAL by default as requested, but ensure it's configured.
# If you ever need it 'weak', you can edit this file via VS Code later.
MANAGER_CONFIG="/root/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    echo "🔒 Enforcing Normal Security for ComfyUI Manager..."
    # This sed command ensures security_level is normal
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

# 4. Start ComfyUI
echo "🎨 Starting ComfyUI..."
cd /root/ComfyUI
# Listen on 0.0.0.0 is critical for RunPod/VS Code Ports
python main.py --listen 0.0.0.0 --port 8188