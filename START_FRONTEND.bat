@echo off
setlocal

REM Add Node.js to PATH
set "PATH=%PATH%;C:\Program Files\nodejs"

echo ========================================
echo Starting FreshSave Frontend
echo ========================================
echo.

cd /d "c:\software_eval\frontend"

echo Starting development server...
echo.
echo The app will open at: http://localhost:5173
echo.

npm run dev
