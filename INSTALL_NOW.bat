@echo off
setlocal

REM Add Node.js to PATH for this session
set "PATH=%PATH%;C:\Program Files\nodejs"

REM Navigate to backend
cd /d "c:\software_eval\backend"

REM Install dependencies
echo Installing backend dependencies...
npm install

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Backend dependencies installed.
    echo.
    echo Next: Add your Firebase serviceAccountKey.json to the backend folder
    echo Then run: npm run dev
) else (
    echo.
    echo Installation failed. Error code: %errorlevel%
)

pause
