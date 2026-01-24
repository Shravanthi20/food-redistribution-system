@echo off
setlocal

REM Add Node.js to PATH
set "PATH=%PATH%;C:\Program Files\nodejs"

echo ========================================
echo Starting FreshSave Backend Server
echo ========================================
echo.

cd /d "c:\software_eval\backend"

REM Check for Firebase service account key
if not exist "serviceAccountKey.json" (
    echo WARNING: serviceAccountKey.json not found!
    echo.
    echo Please download it from Firebase Console:
    echo 1. Go to https://console.firebase.google.com/
    echo 2. Select your project
    echo 3. Go to Project Settings ^> Service Accounts
    echo 4. Click "Generate new private key"
    echo 5. Save as serviceAccountKey.json in the backend folder
    echo.
    pause
    exit /b 1
)

REM Check for .env file
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Creating template...
    (
        echo PORT=5000
        echo MONGODB_URI=mongodb://localhost:27017/freshsave
        echo FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
    ) > .env
    echo.
    echo Please update .env with your MongoDB connection string
    echo.
    pause
)

echo Starting server...
npm run dev
