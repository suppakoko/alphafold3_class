# Alphafold3 Class

## 🧬 Alphafold3 Class — Full Setup Guide

Windows 11 + Ubuntu(WSL2) + Docker + CUDA + UV + af3cli 자동 설치 환경 구축을 위한 매뉴얼

* AlphaFold3 실습환경 Windows → WSL2 Ubuntu → Docker GPU 환경 → af3cli 설정까지 원클릭 설치

---

### 🖥️ 1. Windows 11 Environment Setup

* Windows에서 아래 파일을 관리자 권한으로 실행하세요.
```
1_install_wsl2_ubuntu2204.bat
```
+ Enable WSL2
+ Install Ubuntu 22.04
+ Set default user environment


### 🐧 2. Ubuntu (WSL2) Environment Setup
검색 -> ubuntu -> ubuntu shell 실행
* Ubuntu 터미널에서 아래 스크립트를 실행하세요.
* 2_one_shot_setup.sh 파일을 ubuntu 환경 안으로 이동 또는 생성
```bash
bash 2_one_shot_setup.sh
```
+ Install Docker & NVIDIA Container Toolkit
+ Install CUDA Toolkit
+ Install Python uv
+ Clone af3cli and install it (uv sync)
+ Install wget, zstd
+ Pull AlphaFold3 Docker image
+ Verify GPU availability
