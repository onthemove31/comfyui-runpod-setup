#!/bin/bash

echo "🚀 Starting Custom ComfyUI Container..."

# 1. Activate Virtual Environment
source /root/comfyui/ComfyUI/.venv/bin/activate

# 2. Wait for Internet
echo "📶 Waiting for network..."
until curl -s https://github.com > /dev/null; do sleep 2; done

# 3. VS Code Tunnel Setup
echo "🛠️  Setting up VS Code Tunnel..."
export VSCODE_CLI_DISABLE_KEYCHAIN_ENCRYPT=1
curl -sL 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output /tmp/vscode_cli.tar.gz
tar -xf /tmp/vscode_cli.tar.gz -C /usr/bin

echo "----------------------------------------------------------------"
echo "🔗 AUTHENTICATION REQUIRED"
echo "   Please copy the code below and go to https://microsoft.com/devicelogin"
echo "   (The script will pause here until you log in)"
echo "----------------------------------------------------------------"

# 4. Log in (Block until success)
/usr/bin/code tunnel user login --provider microsoft

# 5. Start the Tunnel (Background)
echo "✅ Login success! Starting Tunnel..."
/usr/bin/code tunnel --accept-server-license-terms --name runpod-gpu &

# 6. Handle ComfyUI Manager Security
MANAGER_CONFIG="/root/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager/config.ini"
if [ -f "$MANAGER_CONFIG" ]; then
    echo "🔒 Enforcing Normal Security for ComfyUI Manager..."
    sed -i 's/security_level = .*/security_level = normal/' "$MANAGER_CONFIG"
fi

echo "----------------------------------------------------------------"
echo "✅ Setup Complete. Tunnel is active."
echo "💤 ComfyUI is NOT running. The pod is sleeping and ready for you."
echo "----------------------------------------------------------------"

# 7. Keep the container alive (Critical!)
sleep infinity