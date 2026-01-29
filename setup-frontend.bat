@echo off
echo ========================================
echo FreshSave Frontend Setup
echo ========================================
echo.

cd frontend

echo [1/2] Installing dependencies...
call npm install

if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    echo Make sure Node.js is installed: https://nodejs.org/
    pause
    exit /b 1
)

echo.
echo [2/2] Checking Firebase configuration...
echo.
echo Please update src/firebase/config.js with your Firebase credentials
echo.
echo Get them from:
echo 1. Go to https://console.firebase.google.com/
echo 2. Select your project
echo 3. Go to Project Settings ^> General
echo 4. Scroll to "Your apps" and copy the firebaseConfig
echo.

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Update src/firebase/config.js with your Firebase config
echo 2. Run: npm run dev
echo 3. Open browser to http://localhost:5173
echo.
pause
