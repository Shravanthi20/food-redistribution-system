@echo off
echo ========================================
echo Installing Backend Dependencies
echo ========================================
echo.

cd /d "%~dp0backend"

echo Installing packages...
call npm install

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Backend dependencies installed successfully!
    echo ========================================
    echo.
    echo To start the backend server:
    echo 1. Add serviceAccountKey.json to backend folder
    echo 2. Update .env with your MongoDB URI  
    echo 3. Run: npm run dev
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
