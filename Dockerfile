# 1. Base Image: NVIDIA CUDA 12.8 on Ubuntu 24.04 (Noble)
# This is the "Runtime" version (Slimmer than Devel, but has libraries needed for Comfy)
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu24.04

# 2. Environment Setup
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
# Force the venv path so all scripts find it automatically
ENV PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

# 3. Install System Dependencies (Ubuntu 24.04 / Python 3.12)
# Note: Python 3.12 removes 'distutils', so we must install python3-setuptools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    git \
    curl \
    wget \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 4. Set Up ComfyUI Directory
WORKDIR /root/comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
WORKDIR /root/comfyui/ComfyUI

# 5. Create Virtual Environment & Install Core
# We use --system-site-packages or just standard venv. 
# Ubuntu 24.04 enforces PEP 668, so venv is mandatory.
RUN python3 -m venv .venv

# 6. Install PyTorch & Comfy Requirements
# Note: For Blackwell, we usually need the nightly or the latest stable compatible with 12.x
# We point to the CUDA 12.4 index (which works on 12.8 drivers) or nightly if strictly required.
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir hf_transfer "huggingface_hub[hf_transfer]" comfy-cli && \
    pip cache purge

# 7. Copy Your Scripts
COPY nodes_list.txt /nodes_list.txt
COPY install_nodes.py /install_nodes.py
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 8. Install Custom Nodes
# We run this INSIDE the build to pre-bake the nodes
RUN python /install_nodes.py && pip cache purge

EXPOSE 8188
ENTRYPOINT ["/start.sh"]