#!/bin/bash
# Fedora Stable (dnf5) XFCE + Podman AI Workstation
set -e

echo "Starting AI Environment Setup (Podman Edition v4.2)..."

# 1. Update and Install Podman & Dev Tools (using dnf5 IDs)
echo "Installing Podman and system utilities..."
sudo dnf5 update -y
sudo dnf5 group install -y development-tools
sudo dnf5 install -y podman git nvtop curl wget policycoreutils-python-utils

# 2. Hardware Driver Logic (NVIDIA via RPM Fusion)
GPU_TYPE=$(lspci | grep -i 'vga\|3d' | grep -Ei "nvidia|amd")

if [[ $GPU_TYPE == *"NVIDIA"* ]]; then
    echo "NVIDIA GPU Detected. Configuring Drivers and Podman Toolkit..."
    
    # Install RPM Fusion
    sudo dnf5 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Using wildcard for enablerepo to ensure we hit the nonfree source
    sudo dnf5 install -y akmod-nvidia xorg-x11-drv-nvidia-cuda --enablerepo=rpmfusion-nonfree*
    
    # Setup NVIDIA Container Toolkit for Podman
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
      sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    
    sudo dnf5 install -y nvidia-container-toolkit

    # Generate CDI (Container Device Interface) configuration for Podman
    echo "Generating NVIDIA CDI for Podman..."
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

    # Fix SELinux to allow containers to access the GPU
    echo "Configuring SELinux for GPU access..."
    sudo setsebool -P container_use_devices 1
fi

# 3. Ollama (Host-based Engine)
echo "Installing/Fixing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Fix: Force enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable --now ollama

# Service Wait Loop
echo "Waiting for Ollama to respond..."
COUNT=0
while ! curl -s http://localhost:11434 > /dev/null; do
    echo "   ...waiting ($((COUNT+1))/10)"
    sleep 3
    ((COUNT++))
    if [ $COUNT -ge 10 ]; then 
        echo "Ollama failed to start. Running manual check..."
        sudo systemctl status ollama
        exit 1
    fi
done

# 4. Model & UI Provisioning via Podman
echo "Pulling Llama 3.2..."
ollama pull llama3.2

echo "Starting Open WebUI container via Podman..."
# Note: --network=host allows the container to talk to Ollama on localhost
sudo podman rm -f ai-webui 2>/dev/null || true
sudo podman run -d --network=host \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name ai-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "-----------------------------------------------------------"
echo "COMPLETE!"
echo "If this is your first time installing NVIDIA drivers, REBOOT NOW."
echo "UI: http://localhost:8080"
echo "-----------------------------------------------------------"
