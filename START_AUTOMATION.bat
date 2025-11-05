@echo off
title Roblox AutoJoiner - VPS MuMu Setup
color 0A

echo ========================================================================
echo   ROBLOX AUTOJOINER - STARTING...
echo ========================================================================
echo.
echo Checking if Python is installed...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed!
    echo Please install Python first.
    pause
    exit /b 1
)

echo Python found!
echo.
echo ========================================================================
echo   CHOOSE MODE:
echo ========================================================================
echo.
echo 1. Full Automation (Discord Monitor + Auto-Join)
echo 2. Server Hopper Only (Auto-Join Random Servers)
echo 3. Exit
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo.
    echo Starting Full Automation...
    echo Discord monitoring + WebSocket server + Auto-join
    echo.
    python main.py
) else if "%choice%"=="2" (
    echo.
    echo Starting Server Hopper...
    echo Auto-joining random servers from Roblox API
    echo.
    python server_hopper.py
) else if "%choice%"=="3" (
    exit /b 0
) else (
    echo Invalid choice!
    pause
    exit /b 1
)

pause

