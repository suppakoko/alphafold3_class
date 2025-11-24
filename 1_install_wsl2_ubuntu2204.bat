@echo off
chcp 65001 >nul

:: =============================================
:: WSL2 + Ubuntu 22.04 Auto Setup Script
:: - Windows 11 전용 가정
:: - Run as Administrator
:: =============================================

:: 0. 관리자 권한 체크
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click this .bat file and choose "Run as administrator".
    pause
    exit /b 1
)

echo.
echo =============================================
echo  WSL2 + Ubuntu 22.04 Auto Setup
echo =============================================
echo.

:: 1. WSL 기능 활성화
echo [1/5] Enabling "Windows Subsystem for Linux" feature...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if %errorlevel% neq 0 (
    echo [WARN] WSL feature may already be enabled or an error occurred.
)

echo.
:: 2. VirtualMachinePlatform 기능 활성화
echo [2/5] Enabling "Virtual Machine Platform" feature...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
if %errorlevel% neq 0 (
    echo [WARN] Virtual Machine Platform may already be enabled or an error occurred.
)

echo.
:: (옵션) Hyper-V를 같이 쓰고 싶으면 주석 해제
:: echo [*] Enabling Hyper-V (optional)...
:: dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

:: 3. 기본 WSL 버전을 2로 설정
echo [3/5] Setting WSL default version to 2...
wsl --set-default-version 2
if %errorlevel% neq 0 (
    echo [WARN] Could not set default version to 2. 
    echo       You may need to reboot once and run this part again:
    echo       wsl --set-default-version 2
)

echo.
:: 4. Ubuntu 22.04 설치
echo [4/5] Installing Ubuntu 22.04 LTS (this may take several minutes)...
echo        Please make sure you are connected to the Internet.
wsl --install -d Ubuntu-22.04
if %errorlevel% neq 0 (
    echo [WARN] Automatic Ubuntu install failed.
    echo       On Windows 11 you can run manually after reboot:
    echo         wsl --install -d Ubuntu-22.04
)

echo.
:: 5. 마무리 및 재부팅 안내
echo [5/5] Setup steps finished.
echo It is strongly recommended to reboot your PC to complete changes.
echo.

choice /M "Do you want to reboot now?"
if errorlevel 2 (
    echo.
    echo Please reboot later to complete WSL2 + Ubuntu 22.04 setup.
    pause
    exit /b 0
) else (
    echo.
    echo Rebooting in 5 seconds...
    shutdown /r /t 5
)
