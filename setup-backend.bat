@echo off
echo ========================================
echo FreshSave Backend Setup
echo ========================================
echo.

cd backend

echo [1/3] Installing dependencies...
call npm install

if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    echo Make sure Node.js is installed: https://nodejs.org/
    pause
    exit /b 1
)

echo.
echo [2/3] Checking for Firebase Service Account Key...
if not exist "serviceAccountKey.json" (
    echo WARNING: serviceAccountKey.json not found!
    echo.
    echo Please download it from Firebase Console:
    echo 1. Go to https://console.firebase.google.com/
    echo 2. Select your project
    echo 3. Go to Project Settings ^> Service Accounts
    echo 4. Click "Generate new private key"
    echo 5. Save the file as "serviceAccountKey.json" in the backend folder
    echo.
    pause
)

echo.
echo [3/3] Checking .env file...
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Creating .env template...
    (
        echo PORT=5000
        echo MONGODB_URI=mongodb://localhost:27017/freshsave
        echo FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
    ) > .env
    echo.
    echo Please update the .env file with your MongoDB connection string
    echo.
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Update .env with your MongoDB URI
echo 2. Add serviceAccountKey.json to backend folder
echo 3. Run: npm run dev
echo.
pause
