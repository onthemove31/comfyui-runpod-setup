##################################
# Stage 1: Builder
##################################
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 10.0 12.0" \
    PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

WORKDIR /root/comfyui

# Install all build deps in a single RUN + clean up
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       git curl build-essential cmake wget \
       python3.10 python3-pip python3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Clone repo
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI

WORKDIR /root/comfyui/ComfyUI

# Create venv, install dependencies in one RUN to minimize layers
RUN python3.10 -m venv .venv \
    && . .venv/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cu128 \
    && pip install --no-cache-dir -r requirements.txt \
                   hf_transfer "huggingface_hub[hf_transfer]" comfy-cli \
                   opencv-python-headless \
    && rm -rf /root/.cache/pip

# Install custom nodes + clean caches
COPY nodes_list.txt install_nodes.py ./
RUN . .venv/bin/activate \
    && python install_nodes.py \
    && rm -rf /root/.cache/pip

# Aggressive cleanup of unneeded files (tests, docs, git metadata, pycache)
RUN find .venv -type d \( -name "test*" -o -name "docs" -o -name "__pycache__" \) -exec rm -rf {} + \
    && find . -type d -name ".git" -exec rm -rf {} +

##################################
# Stage 2: Runtime
##################################
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

WORKDIR /root/comfyui

# Added htop, nvtop, tmux back for debugging capability
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       python3.10 python3-venv ffmpeg curl git openssh-client openssl rsync unzip \
       htop nvtop tmux \
    && rm -rf /var/lib/apt/lists/*

# Copy only what we need from builder
COPY --from=builder /root/comfyui /root/comfyui
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root/comfyui/ComfyUI
EXPOSE 8188
ENTRYPOINT ["/start.sh"]