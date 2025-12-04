# 1. Base Image (Optimized for Compilation)
# Note: If 12.8.1 fails to pull, try 12.8.0-cudnn-devel-ubuntu22.04
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

LABEL authors="onthemove31"

# 2. Environment Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
# Target Architectures for compiling nodes (Includes Blackwell 10.0)
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 10.0 12.0"
# Force scripts to use the venv
ENV PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

# 3. Install System Dependencies (Your optimized list)
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    curl \
    build-essential \
    cmake \
    wget \
    python3.10 \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    python3-venv \
    ffmpeg \
    tmux \
    htop \
    nvtop \
    libgl1-mesa-glx \
    libglib2.0-0 \
    openssh-client \
    openssh-server \
    openssl \
    rsync \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. Set Up ComfyUI Directory
WORKDIR /root/comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
WORKDIR /root/comfyui/ComfyUI

# 5. Virtual Environment & PyTorch
# We use system python3.10 to create the venv
RUN python3.10 -m venv .venv

# Install Pip & PyTorch (CUDA 12.4 build works on 12.8 drivers)
# We use --no-cache-dir everywhere to keep the layer small
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir hf_transfer "huggingface_hub[hf_transfer]" comfy-cli && \
    pip cache purge

# 6. Copy Your Helper Scripts
COPY nodes_list.txt /nodes_list.txt
COPY install_nodes.py /install_nodes.py
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 7. Install Custom Nodes
# The script will inherit the 'TORCH_CUDA_ARCH_LIST' env var, 
# speeding up compilation for nodes like Flash Attention.
RUN python /install_nodes.py && pip cache purge

EXPOSE 8188
ENTRYPOINT ["/start.sh"]