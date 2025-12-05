import os
import subprocess
import sys

CUSTOM_NODES_DIR = "/root/comfyui/ComfyUI/custom_nodes"

def run_command(command):
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError:
        pass

def install_nodes(clone_only=False):
    if not os.path.exists(CUSTOM_NODES_DIR):
        os.makedirs(CUSTOM_NODES_DIR)

    with open("nodes_list.txt", "r") as f:
        urls = [line.strip() for line in f if line.strip()]

    for url in urls:
        repo_name = url.split("/")[-1].replace(".git", "")
        repo_path = os.path.join(CUSTOM_NODES_DIR, repo_name)

        if not os.path.exists(repo_path):
            print(f"⬇️ Cloning {repo_name}...")
            run_command(f"git clone --depth 1 {url} {repo_path}")
        
        if clone_only:
            continue

        req_path = os.path.join(repo_path, "requirements.txt")
        if os.path.exists(req_path):
            print(f"📦 Installing requirements {repo_name}...")
            run_command(f"pip install --no-cache-dir -r {req_path}")
            
        install_py = os.path.join(repo_path, "install.py")
        if os.path.exists(install_py):
             run_command(f"python {install_py}")

if __name__ == "__main__":
    # Check for flag
    clone_mode = "--clone-only" in sys.argv
    install_nodes(clone_only=clone_mode)