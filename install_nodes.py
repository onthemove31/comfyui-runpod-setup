import os
import subprocess
import sys

# Define path
CUSTOM_NODES_DIR = "/root/ComfyUI/custom_nodes"

def run_command(command):
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}")
        # We don't exit, we keep trying other nodes
        pass

def install_nodes():
    if not os.path.exists(CUSTOM_NODES_DIR):
        os.makedirs(CUSTOM_NODES_DIR)

    with open("/nodes_list.txt", "r") as f:
        urls = [line.strip() for line in f if line.strip()]

    print(f"Found {len(urls)} nodes to install...")

    for url in urls:
        repo_name = url.split("/")[-1].replace(".git", "")
        repo_path = os.path.join(CUSTOM_NODES_DIR, repo_name)

        if os.path.exists(repo_path):
            print(f"Skipping {repo_name}, already exists.")
            continue

        print(f"⬇️ Cloning {repo_name}...")
        run_command(f"git clone {url} {repo_path}")

        # Install Requirements
        req_path = os.path.join(repo_path, "requirements.txt")
        if os.path.exists(req_path):
            print(f"📦 Installing requirements for {repo_name}...")
            run_command(f"pip install -r {req_path}")
        
        # Some nodes use install.py
        install_py = os.path.join(repo_path, "install.py")
        if os.path.exists(install_py):
             print(f"⚙️ Running install.py for {repo_name}...")
             run_command(f"python {install_py}")

if __name__ == "__main__":
    install_nodes()