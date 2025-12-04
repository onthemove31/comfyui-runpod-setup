# Custom ComfyUI + VS Code Tunnel (RunPod Optimized)

A production-ready Docker environment designed for high-performance AI generation on **RunPod**. This image includes a pre-installed, "batteries-included" ComfyUI setup with 30+ popular custom nodes, running on a slim NVIDIA CUDA 12.8 base with full support for Blackwell GPUs.

Features a **Stateless VS Code Tunnel**, allowing you to connect your local VS Code directly to the cloud GPU without opening SSH ports or managing keys.

## Features

  * **Base:** NVIDIA CUDA 12.8.0 Devel (Ubuntu 22.04) — Optimized for compilation.
  * **Python:** 3.10 (Stable standard for ComfyUI).
  * **ComfyUI:** Pre-installed in `/root/comfyui/ComfyUI`.
  * **Custom Nodes:** 30+ pre-baked nodes (Manager, Impact Pack, ControlNet, etc.) to eliminate startup installation time.
  * **Remote Access:** Microsoft VS Code Tunnels (No VPN/SSH required).
  * **Size:** Optimized to \~6-8GB (vs 15GB+ for standard PyTorch images).
  * **CI/CD:** Automatic builds via GitHub Actions (`:dev` and `:latest` tags).

-----

## RunPod Deployment Guide

### 1\. Template Settings

Create a new RunPod Template with these settings:

  * **Image Name:** `gghcr.io/onthemove31/comfyui-runpod-setup:latest`
  * **Container Disk:** `20 GB` (Minimum)
  * **Volume Mount Path:** `/workspace`
      * *Note: Do NOT mount to `/root`. Use workspace for storing images/models.*
  * **Exposed Ports:** `8188` (Optional, as we use Tunnels).

### 2\. Environment Variables

Add these to your pod or template to auto-configure nodes:

| Key | Value | Description |
| :--- | :--- | :--- |
| `HUGGINGFACE_TOKEN` | `hf_...` | For downloading private models |
| `CIVITAI_API_KEY` | `...` | For CivitAI node integration |
| `HF_HUB_ENABLE_HF_TRANSFER` | `1` | Enables fast downloads |

### 3\. Docker Command (Critical)

To ensure the startup script runs and handles the login flow correctly, set the **Docker Command** field to:

```bash
bash /start.sh
```

-----

## How to Connect

### 1\. Authenticate (First Boot)

1.  Deploy the Pod.
2.  Click **Connect** → **Logs**.
3.  Wait for the message:
    > `🔗 AUTHENTICATION REQUIRED`
    > `Please copy the code below and go to https://microsoft.com/devicelogin`
4.  Copy the 8-digit code from the logs.
5.  Go to the URL on your local PC and authorize the device.
6.  The logs will update to `✅ Login success!` and ComfyUI will start.

### 2\. Connect via VS Code

1.  Open VS Code on your local machine.
2.  Install the **Remote - Tunnels** extension.
3.  Click the Remote icon (Green/Blue bottom left) or the Remote tab.
4.  Select **Tunnels** and find `runpod-gpu`.
5.  Right-click → **Connect in Current Window**.

### 3\. Access ComfyUI

1.  Once connected in VS Code, open the **Ports** tab (`Ctrl + ~` to open terminal panel).
2.  Find port **8188**.
3.  Click the **Globe Icon** 🌐 to open ComfyUI in your local browser (`localhost:8188`).

-----

## Included Custom Nodes

This image comes pre-loaded with the following nodes (defined in `nodes_list.txt`):

  * **Essentials:** ComfyUI-Manager, ComfyUI-Custom-Scripts, rgthree-comfy
  * **Control/Logic:** Impact Pack, Inspire Pack, Use-Everywhere
  * **Generation:** ControlNet Aux, UltimateSDUpscale, IpAdapter
  * **Video:** VideoHelperSuite, Frame Interpolation, WanVideoWrapper
  * *...and many more.*

To add new nodes, update `nodes_list.txt` and push to the `main` branch. GitHub Actions will rebuild the image automatically.

-----

## Directory Structure

  * **`/root/comfyui/ComfyUI`**: The main application.
  * **`/root/comfyui/ComfyUI/custom_nodes`**: Where your nodes live.
  * **`/workspace`**: Your persistent RunPod volume (Use this for outputs\!).

### Model Management

To save disk space and keep models across sessions, it is recommended to store checkpoints in `/workspace` and use an `extra_model_paths.yaml` file to point ComfyUI to them.

-----