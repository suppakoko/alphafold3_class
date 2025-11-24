#!/usr/bin/env bash
set -e

echo "========================================="
echo "  Docker + NVIDIA CUDA Docker Toolkit"
echo "  Auto Install Script for WSL2 (Ubuntu 22.04)"
echo "========================================="
echo

# 0. Ubuntu 버전 체크
if command -v lsb_release >/dev/null 2>&1; then
    DISTRO_CODENAME=$(lsb_release -cs)
    if [ "$DISTRO_CODENAME" != "jammy" ]; then
        echo "[WARN] This script is optimized for Ubuntu 22.04 (jammy)."
        echo "       Detected: $DISTRO_CODENAME"
        echo "       Continue at your own risk."
        read -p "Press Enter to continue or Ctrl+C to abort..."
    fi
fi

# 1. 기존 Docker 관련 패키지 제거
echo "[1/8] Removing old Docker packages (if any)..."
sudo apt remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1 || true

# 2. 필수 패키지 설치
echo "[2/8] Installing required packages (ca-certificates, curl, gnupg, lsb-release)..."
sudo apt update -y
sudo apt install -y ca-certificates curl gnupg lsb-release

# 3. Docker GPG 키 & APT 저장소 설정
echo "[3/8] Adding Docker official GPG key and repository..."
sudo mkdir -m 0755 -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
sudo chmod a+r /etc/apt/keyrings/docker.gpg

UBUNTU_CODENAME=$(lsb_release -cs)
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Docker Engine + CLI + Buildx + Compose 설치
echo "[4/8] Installing Docker Engine, CLI, Buildx, and Compose..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. 현재 유저를 docker 그룹에 추가 (sudo 없이 docker 사용용)
echo "[5/8] Adding current user to 'docker' group..."
sudo groupadd docker >/dev/null 2>&1 || true
sudo usermod -aG docker "$USER"

# 6. NVIDIA Container Toolkit (CUDA Docker Toolkit) 설치
echo "[6/8] Installing NVIDIA Container Toolkit (CUDA Docker support)..."

if command -v nvidia-smi >/dev/null 2>&1; then
    echo "    Detected 'nvidia-smi'. Setting up NVIDIA Container Toolkit..."

    # 배포판 이름 (예: ubuntu22.04)
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

    # GPG 키 등록
    sudo mkdir -p /usr/share/keyrings
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

    # repo 설정 (배포판별)
    curl -fsSL "https://nvidia.github.io/libnvidia-container/stable/$distribution/libnvidia-container.list" | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

    sudo apt update -y
    # nvidia-docker2를 설치하면 Docker + NVIDIA 런타임 설정 패키지가 같이 들어감
    sudo apt install -y nvidia-docker2

    echo "    Configuring NVIDIA runtime for Docker..."
    sudo nvidia-ctk runtime configure --runtime=docker || true

    echo "    Trying to restart Docker daemon (systemd or service)..."
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart docker || echo "    [WARN] systemctl restart docker failed (WSL without systemd?)"
    else
        sudo service docker restart || echo "    [WARN] service docker restart failed (WSL without service docker?)."
    fi

    echo "    NVIDIA CUDA Docker Toolkit installation done."
else
    echo "    [WARN] 'nvidia-smi' not found inside WSL."
    echo "    - Make sure you have a supported NVIDIA driver installed on Windows"
    echo "      (WSL2 + CUDA 지원 드라이버)."
    echo "    - After that, open a NEW Ubuntu (WSL) session and re-run this part if needed."
fi

# 7. 간단한 Docker 동작 테스트 안내
echo "[7/8] Basic Docker test commands (run after re-login):"
echo "    docker version"
echo "    docker run --rm hello-world"

# 8. CUDA + Docker 동작 테스트 안내
echo "[8/8] CUDA in Docker test command (after re-login):"
echo "    docker run --rm --gpus all nvidia/cuda:12.3.0-base nvidia-smi"
echo

echo "========================================="
echo " Installation steps completed."
echo " - Docker CLI:        docker"
echo " - Docker Compose:    docker compose"
echo " - NVIDIA Docker:     nvidia-docker2 + runtime"
echo "========================================="
echo
echo "IMPORTANT:"
echo "  1) CLOSE this terminal completely."
echo "  2) Open a NEW Ubuntu (WSL2) terminal."
echo "  3) Then run the test commands:"
echo "       docker version"
echo "       docker run --rm hello-world"
echo "       docker run --rm --gpus all nvidia/cuda:12.3.0-base nvidia-smi"
echo

exit 0
