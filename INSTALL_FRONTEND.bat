@echo off
setlocal

REM Add Node.js to PATH for this session
set "PATH=%PATH%;C:\Program Files\nodejs"

REM Navigate to frontend
cd /d "c:\software_eval\frontend"

REM Install dependencies
echo Installing frontend dependencies...
npm install

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS! Frontend dependencies installed.
    echo.
    echo Next: Update src/firebase/config.js with your Firebase credentials
    echo Then run: npm run dev
) else (
    echo.
    echo Installation failed. Error code: %errorlevel%
)

pause
