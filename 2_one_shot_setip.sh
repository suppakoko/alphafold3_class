#!/usr/bin/env bash
set -euo pipefail

echo "====================================================="
echo "  FULL SETUP: Docker + CUDA Toolkit + UV + af3cli"
echo "  (For WSL2 / Ubuntu 22.04)"
echo "====================================================="
echo

#-------------------------------------------------------------------------------
# 0. Prerequisite check
#-------------------------------------------------------------------------------
for cmd in git curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] '$cmd' command not found. Install it first:"
        echo "  sudo apt install -y git curl"
        exit 1
    fi
done

echo "[INFO] System detected: $(lsb_release -d -s)"
echo

#-------------------------------------------------------------------------------
# 1. Docker + NVIDIA Container Toolkit + Runtime Setup
#-------------------------------------------------------------------------------
echo "====================================================="
echo "[1/4] Installing Docker Engine + NVIDIA GPU Toolkit..."
echo "====================================================="

# Remove old Docker
sudo apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1 || true

# Install required packages
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repo
UBUNTU_CODENAME=$(lsb_release -cs)
echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update -y
sudo apt install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo groupadd docker >/dev/null 2>&1 || true
sudo usermod -aG docker "$USER"

echo "[INFO] Docker installation done."

#-------------------------------------------------------------------------------
# 1-2. NVIDIA Container Toolkit (CUDA for Docker)
#-------------------------------------------------------------------------------
echo
echo "====================================================="
echo "[1-2] Installing NVIDIA Container Toolkit (CUDA Docker Runtime)"
echo "====================================================="

if command -v nvidia-smi >/dev/null 2>&1; then
    echo "GPU detected in WSL. Installing toolkit..."

    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

    sudo apt update -y
    sudo apt install -y nvidia-docker2

    echo "[INFO] Configuring NVIDIA Docker runtime..."
    sudo nvidia-ctk runtime configure --runtime=docker || true

    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart docker || true
    else
        sudo service docker restart || true
    fi

    echo "[INFO] NVIDIA CUDA Docker Toolkit installed."
else
    echo "[WARN] 'nvidia-smi' not found inside WSL. GPU not available right now."
    echo "       Install WSL2-compatible NVIDIA driver on Windows then reopen WSL."
fi

#-------------------------------------------------------------------------------
# 2. Docker pull for AlphaFold3 clean image
#-------------------------------------------------------------------------------
echo
echo "====================================================="
echo "[2/4] Pulling AlphaFold3 Docker image"
echo "====================================================="

docker pull suppak/alphafold3:clean


#-------------------------------------------------------------------------------
# 3. Install uv
#-------------------------------------------------------------------------------
echo
echo "====================================================="
echo "[3/4] Installing uv (Python package manager)"
echo "====================================================="

if command -v uv >/dev/null 2>&1; then
    echo "[INFO] uv already installed at: $(command -v uv)"
else
    echo "[INFO] Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

#-------------------------------------------------------------------------------
# 4. Clone af3cli + uv sync --locked
#-------------------------------------------------------------------------------
echo
echo "====================================================="
echo "[4/4] Cloning af3cli and configuring environment"
echo "====================================================="

if [ ! -d "af3cli" ]; then
    git clone https://github.com/SLx64/af3cli.git
else
    echo "[INFO] Directory 'af3cli' already exists. Using it."
fi

cd af3cli

echo "[INFO] Running uv sync --locked..."
uv sync --locked

echo
echo "====================================================="
echo "  Installation Complete!"
echo
echo "  - Docker + NVIDIA Toolkit configured"
echo "  - UV installed"
echo "  - af3cli cloned and environment created"
echo "  - AF3 Docker image pulled"
echo
echo "IMPORTANT:"
echo "  EXIT this terminal and open a NEW WSL terminal so the Docker group"
echo "  permissions apply."
echo
echo "Test commands after reopening WSL:"
echo "  docker run --rm hello-world"
echo "  docker run --rm --gpus all nvidia/cuda:12.3.0-base nvidia-smi"
echo
echo "====================================================="
