@echo off
echo ========================================================================
echo   VPS + MUMU SETUP AUTOMATION SCRIPT
echo ========================================================================
echo.

echo Checking Python installation...
python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH!
    echo Please install Python 3.11+ from python.org
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo.
echo Python is installed!
echo.
echo Installing dependencies...
pip install -r requirements.txt

if errorlevel 1 (
    echo.
    echo ERROR: Failed to install dependencies!
    echo Try running manually: pip install -r requirements.txt
    pause
    exit /b 1
)

echo.
echo ========================================================================
echo   DEPENDENCIES INSTALLED SUCCESSFULLY!
echo ========================================================================
echo.
echo Next steps:
echo 1. Edit config.py with your Discord token and webhooks
echo 2. Install MuMu Player emulator
echo 3. Setup Roblox and executor in MuMu
echo 4. Copy Lua scripts to executor auto-exec folder
echo 5. Find VPS IP address: ipconfig
echo 6. Update Lua script WebSocket URL with VPS IP
echo 7. Run: python main.py
echo.
echo See VPS_SETUP_MUMU.txt for complete instructions!
echo.
pause

