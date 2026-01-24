@echo off
echo ========================================
echo Installing Frontend Dependencies
echo ========================================
echo.

cd /d "%~dp0frontend"

echo Installing packages...
call npm install

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Frontend dependencies installed successfully!
    echo ========================================
    echo.
    echo To start the frontend:
    echo 1. Update src/firebase/config.js with your Firebase credentials
    echo 2. Run: npm run dev
    echo 3. Open browser to http://localhost:5173
    echo.
) else (
    echo.
    echo ========================================
    echo Installation failed!
    echo ========================================
    echo Please close this window and open a NEW terminal
    echo Then run this script again.
    echo.
)

pause
