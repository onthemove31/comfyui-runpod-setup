##################################
# Stage 1: Builder
##################################
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    TORCH_CUDA_ARCH_LIST="8.0 8.6 8.9 9.0 10.0 12.0" \
    PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

WORKDIR /root/comfyui

# 1. Install Build Dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       git curl build-essential cmake wget \
       python3.10 python3-pip python3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 2. Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI

WORKDIR /root/comfyui/ComfyUI

# 3. Create venv & Install PyTorch Nightly
RUN python3.10 -m venv .venv \
    && . .venv/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && pip install --no-cache-dir -r requirements.txt \
                   hf_transfer "huggingface_hub[hf_transfer]" comfy-cli \
                   opencv-python-headless \
    && rm -rf /root/.cache/pip

# ======================================================
# 4. INSTALL SAGEATTENTION (User Config)
# ======================================================
# Switch to /root so we don't install it inside ComfyUI folder
WORKDIR /root

# Clone Repo
RUN git clone https://github.com/thu-ml/SageAttention.git

WORKDIR /root/SageAttention

# Compile & Install with acceleration flags
# We use the venv python (via PATH)
RUN export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 4" MAX_JOBS=32 && \
    python setup.py install

# Switch back to ComfyUI for the rest of the build
WORKDIR /root/comfyui/ComfyUI
# ======================================================

# 5. Install custom nodes + clean caches
COPY nodes_list.txt install_nodes.py ./
RUN . .venv/bin/activate \
    && python install_nodes.py \
    && rm -rf /root/.cache/pip

# 6. Aggressive cleanup
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

# Install Runtime Deps (added htop/nvtop/tmux back)
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
       python3.10 python3-venv ffmpeg curl git openssh-client openssl rsync unzip \
       htop nvtop tmux \
    && rm -rf /var/lib/apt/lists/*

# Copy ComfyUI (which now includes SageAttention inside site-packages)
COPY --from=builder /root/comfyui /root/comfyui
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root/comfyui/ComfyUI
EXPOSE 8188
ENTRYPOINT ["/start.sh"]