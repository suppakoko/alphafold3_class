# Alphafold3 Class

🧬 Alphafold3 Class — Full Setup Guide

Windows 11 + Ubuntu(WSL2) + Docker + CUDA + UV + af3cli 자동 설치 환경 구축을 위한 완전한 매뉴얼

본 문서는 AlphaFold3 실습을 위해 Windows → WSL2 Ubuntu → Docker GPU 환경 → af3cli 설정까지
원클릭 설치 스크립트 기반으로 전체 환경 구축 과정을 설명합니다.


🖥️ 1. Windows 11 Environment Setup

Windows에서 아래 파일을 관리자 권한으로 실행하세요.

1_install_wsl2_ubuntu2204.bat

This will:

Enable WSL2

Install Ubuntu 22.04

Set default user environment


🐧 2. Ubuntu (WSL2) Environment Setup

Ubuntu 터미널에서 아래 스크립트를 실행하세요.

bash 2_one_shot_setup.sh


This script will automatically:

Install Docker & NVIDIA Container Toolkit

Install CUDA Toolkit

Install Python uv

Clone af3cli and install it (uv sync)

Install wget, zstd

Pull AlphaFold3 Docker image

Verify GPU availability
