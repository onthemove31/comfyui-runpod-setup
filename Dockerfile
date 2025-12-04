# ==========================================
# STAGE 1: BUILDER (The Heavy Lifter)
# ==========================================
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 10.0 12.0"
ENV PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

# 1. Install Build Dependencies
# We need 'build-essential' and 'git' here to compile nodes
RUN apt-get update && apt-get install --no-install-recommends -y \
    git curl build-essential cmake wget \
    python3.10 python3-pip python3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 2. Set Up & Install ComfyUI
WORKDIR /root/comfyui
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
WORKDIR /root/comfyui/ComfyUI

# 3. Create Venv & Install PyTorch (Nightly for 5090)
RUN python3.10 -m venv .venv
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir hf_transfer "huggingface_hub[hf_transfer]" comfy-cli && \
    pip cache purge

# 4. Install Custom Nodes
COPY nodes_list.txt /nodes_list.txt
COPY install_nodes.py /install_nodes.py
# This runs the heavy compilations (using the Devel compilers)
RUN python /install_nodes.py && pip cache purge

# 5. AGGRESSIVE CLEANUP (The Secret Sauce)
# Delete all .git folders (saves ~1GB) and compiled cache
RUN find . -name ".git" -type d -exec rm -rf {} + && \
    find . -name "__pycache__" -type d -exec rm -rf {} +

# ==========================================
# STAGE 2: RUNTIME (The Final Slim Image)
# ==========================================
# We switch to the 'runtime' image which is ~3GB smaller
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

LABEL authors="onthemove31"
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

# 1. Install ONLY Runtime Dependencies
# No compilers (gcc/cmake) needed here!
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3.10 python3-venv \
    ffmpeg libgl1-mesa-glx libglib2.0-0 \
    curl git openssh-client openssl rsync unzip htop nvtop tmux \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Copy the entire pre-built application from the Builder stage
# This copies ComfyUI + Venv + Custom Nodes all at once
COPY --from=builder /root/comfyui /root/comfyui

# 3. Copy Startup Scripts
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root/comfyui/ComfyUI
EXPOSE 8188
ENTRYPOINT ["/start.sh"]