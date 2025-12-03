# Use Official PyTorch Image
FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies
RUN apt-get update && apt-get install -y \
    git curl tar wget \
    ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 2. Set Up ComfyUI (Updated Path)
# Create the parent directory first
WORKDIR /root/comfyui
# Clone ComfyUI into the nested folder
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI

# Move context to the actual ComfyUI application folder
WORKDIR /root/comfyui/ComfyUI

# ------------------------------------------------------------------
# 3. VIRTUAL ENVIRONMENT SETUP
# ------------------------------------------------------------------
RUN python3 -m venv .venv

# MAGIC LINE: Update PATH to the new location
ENV PATH="/root/comfyui/ComfyUI/.venv/bin:$PATH"

# 4. Install Requirements
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir hf_transfer "huggingface_hub[hf_transfer]" comfy-cli

# 5. Copy Scripts
COPY nodes_list.txt /nodes_list.txt
COPY install_nodes.py /install_nodes.py
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 6. Run the Installer
RUN python /install_nodes.py

EXPOSE 8188
ENTRYPOINT ["/start.sh"]