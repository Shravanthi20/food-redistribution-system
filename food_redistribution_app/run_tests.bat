@echo off
:: Development Testing Script for Food Redistribution App
:: Run this file: run_tests.bat

title Food Redistribution App - Test Suite

:menu
cls
echo 🍽️  Food Redistribution App - Test Suite
echo =======================================
echo.
echo Choose testing option:
echo 1. Run matching algorithm simulation
echo 2. Run Flutter unit tests (if working)  
echo 3. Run Flutter widget tests
echo 4. Build and run app (manual testing)
echo 5. Run static analysis
echo 6. Test Firebase connection
echo 7. Quick smoke test
echo 8. Exit
echo.

set /p choice="Enter choice (1-8): "
echo.

if "%choice%"=="1" goto test_matching
if "%choice%"=="2" goto test_unit
if "%choice%"=="3" goto test_widgets
if "%choice%"=="4" goto test_manual
if "%choice%"=="5" goto test_analysis
if "%choice%"=="6" goto test_firebase
if "%choice%"=="7" goto test_smoke
if "%choice%"=="8" goto exit
echo ❌ Invalid option. Please choose 1-8.
pause
goto menu

:test_matching
echo 🎯 Testing Matching Algorithms...
echo.
dart run test_matching.dart
echo.
pause
goto menu

:test_unit
echo 🧪 Running Flutter Unit Tests...
echo.
flutter test test/unit/ --reporter=expanded
echo.
pause
goto menu

:test_widgets
echo 🖼️  Running Widget Tests...
echo.
flutter test test/widget/ --reporter=expanded
echo.
pause
goto menu

:test_manual
echo 📱 Building and Running App for Manual Testing...
echo.
echo Building Flutter app...
flutter build apk --debug
echo.
echo Starting app on connected device/emulator...
flutter run --debug
echo.
pause
goto menu

:test_analysis
echo 🔍 Running Static Analysis...
echo.
flutter analyze --no-congratulate
echo.
pause
goto menu

:test_firebase
echo 🔥 Testing Firebase Connection...
echo.
echo Checking Firebase configuration...

if exist "android\app\google-services.json" (
    echo ✅ Android Firebase config found
) else (
    echo ❌ Android Firebase config missing
)

if exist "ios\Runner\GoogleService-Info.plist" (
    echo ✅ iOS Firebase config found
) else (
    echo ❌ iOS Firebase config missing
)

if exist "firebase.json" (
    echo ✅ Firebase project config found
) else (
    echo ❌ Firebase project config missing
)

echo.
echo To test Firebase connection, run the app and check logs for:
echo - Firebase initialization messages
echo - Authentication connection status 
echo - Firestore connection status
echo.
pause
goto menu

:test_smoke
echo 🚀 Running Quick Smoke Test...
echo.
echo 1. Checking Flutter installation...
flutter --version
echo.
echo 2. Checking dependencies...
flutter pub get
echo.
echo 3. Running basic analysis...
flutter analyze --no-congratulate | findstr "issues found"
echo.
echo 4. Testing matching algorithm...
dart run test_matching.dart
echo.
echo ✅ Smoke test complete!
echo.
pause
goto menu

:exit
echo 👋 Goodbye!
exit