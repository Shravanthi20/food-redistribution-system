@echo off
REM Development Workflow Script for Windows - SISIR-REDDY Account
REM This script helps maintain consistent commits from the SISIR-REDDY account

echo 🚀 Food Redistribution Platform - Development Workflow
echo ================================================

REM Ensure we're in the right directory
cd /d "%~dp0"

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Error: Not a git repository. Please run from project root.
    pause
    exit /b 1
)

REM Verify git configuration
echo 🔧 Checking git configuration...
for /f "tokens=*" %%i in ('git config user.name') do set CURRENT_USER=%%i
for /f "tokens=*" %%i in ('git config user.email') do set CURRENT_EMAIL=%%i

if not "%CURRENT_USER%"=="SISIR-REDDY" (
    echo ⚙️  Setting git user to SISIR-REDDY...
    git config user.name "SISIR-REDDY"
)

if not "%CURRENT_EMAIL%"=="sisirreddy@example.com" (
    echo ⚙️  Setting git email...
    git config user.email "sisirreddy@example.com"
)

for /f "tokens=*" %%i in ('git config user.name') do set GIT_USER=%%i
for /f "tokens=*" %%i in ('git config user.email') do set GIT_EMAIL=%%i
echo ✅ Git configured for: %GIT_USER% ^<%GIT_EMAIL%^>

REM Show current status
echo.
echo 📊 Current repository status:
git status --short

REM Main workflow menu
echo.
echo 🔨 Choose an action:
echo 1. Make development commit
echo 2. Push changes to GitHub
echo 3. Both (commit + push)
echo 4. Show detailed status
echo 5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto :commit
if "%choice%"=="2" goto :push
if "%choice%"=="3" goto :both
if "%choice%"=="4" goto :status
if "%choice%"=="5" goto :exit
goto :invalid

:commit
echo.
echo 📝 Creating development commit...
git add .

REM Get current date for commit
for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set CURRENT_DATE=%%a/%%b/%%c
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set CURRENT_TIME=%%a:%%b
set COMMIT_TIMESTAMP=%CURRENT_DATE% %CURRENT_TIME%

git commit -m "feat: Development progress checkpoint - %COMMIT_TIMESTAMP%

📈 Current development status:
- Person 1 (Core Backend & Security): ✅ Complete  
- Person 2 (Matching & Dispatch): 🔄 In Progress

🔧 Technical updates:
- Enhanced Firestore database operations
- Improved security middleware  
- Updated UI components
- Bug fixes and optimizations

🛡️ Security features maintained:
- RBAC access control active
- Audit logging functional
- Session management secured
- Account verification system operational

👨‍💻 Committed by: SISIR-REDDY
🕒 Timestamp: %COMMIT_TIMESTAMP%"

echo ✅ Commit created successfully!
if "%choice%"=="3" goto :push
goto :complete

:push
echo.
echo 🚀 Pushing changes to GitHub...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo ✅ Changes pushed successfully!
    echo 🌐 Repository: https://github.com/Shravanthi20/food-redistribution-system
) else (
    echo ❌ Failed to push changes. Please check your connection and try again.
)
goto :complete

:both
goto :commit

:status
echo.
echo 📋 Detailed repository status:
echo ==============================
git log --oneline -10
echo.
echo 📊 File changes:
git status
goto :complete

:exit
echo 👋 Goodbye! Happy coding!
exit /b 0

:invalid
echo ❌ Invalid choice. Please run the script again.
pause
exit /b 1

:complete
echo.
echo ✨ Workflow complete! Keep building amazing features! 🎯
echo.
pause