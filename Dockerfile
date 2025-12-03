# Use Official PyTorch Image (Includes CUDA 12.4 & Python 3.11+)
FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

# prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies
# ffmpeg: required for VideoHelperSuite & WanVideo
# git/curl: required for setup
# libgl1: required for OpenCV (Impact Pack)
RUN apt-get update && apt-get install -y \
    git curl tar wget \
    ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 2. Set Up ComfyUI
WORKDIR /root
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 3. Install ComfyUI Core Requirements
WORKDIR /root/ComfyUI
RUN pip install --upgrade pip
RUN pip install -r requirements.txt
# Install extra dependencies requested by your custom nodes
RUN pip install hf_transfer "huggingface_hub[hf_transfer]" comfy-cli

# 4. Copy Node List & Installer
COPY nodes_list.txt /nodes_list.txt
COPY install_nodes.py /install_nodes.py

# 5. Run the Custom Node Installer
RUN python /install_nodes.py

# 6. Copy Startup Script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose ComfyUI Port
EXPOSE 8188

ENTRYPOINT ["/start.sh"]