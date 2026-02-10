#!/usr/bin/env bash

# Development Testing Script for Food Redistribution App
# Make this executable with: chmod +x run_tests.sh

echo "🍽️  Food Redistribution App - Test Suite"
echo "======================================="
echo ""

# Function to show test options
show_menu() {
    echo "Choose testing option:"
    echo "1. Run matching algorithm simulation"
    echo "2. Run Flutter unit tests (if working)"  
    echo "3. Run Flutter widget tests"
    echo "4. Build and run app (manual testing)"
    echo "5. Run static analysis"
    echo "6. Test Firebase connection"
    echo "7. Exit"
    echo ""
}

# Matching algorithm test
test_matching() {
    echo "🎯 Testing Matching Algorithms..."
    echo ""
    dart run test_matching.dart
    echo ""
}

# Flutter unit tests
test_unit() {
    echo "🧪 Running Flutter Unit Tests..."
    echo ""
    flutter test test/unit/ --reporter=expanded
    echo ""
}

# Widget tests  
test_widgets() {
    echo "🖼️  Running Widget Tests..."
    echo ""
    flutter test test/widget/ --reporter=expanded
    echo ""
}

# Build and run app
test_manual() {
    echo "📱 Building and Running App for Manual Testing..."
    echo ""
    echo "Building Flutter app..."
    flutter build apk --debug
    
    echo ""
    echo "Starting app on connected device/emulator..."
    flutter run --debug
    echo ""
}

# Static analysis
test_analysis() {
    echo "🔍 Running Static Analysis..."
    echo ""
    flutter analyze --no-congratulate
    echo ""
}

# Firebase connection test
test_firebase() {
    echo "🔥 Testing Firebase Connection..."
    echo ""
    echo "Checking Firebase configuration..."
    
    if [ -f "android/app/google-services.json" ]; then
        echo "✅ Android Firebase config found"
    else
        echo "❌ Android Firebase config missing"
    fi
    
    if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
        echo "✅ iOS Firebase config found"
    else
        echo "❌ iOS Firebase config missing"
    fi
    
    if [ -f "firebase.json" ]; then
        echo "✅ Firebase project config found"
    else
        echo "❌ Firebase project config missing"
    fi
    
    echo ""
    echo "To test Firebase connection, run the app and check logs for:"
    echo "- Firebase initialization messages"
    echo "- Authentication connection status"
    echo "- Firestore connection status"
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter choice (1-7): " choice
    echo ""
    
    case $choice in
        1)
            test_matching
            ;;
        2)
            test_unit
            ;;
        3)
            test_widgets
            ;;
        4)
            test_manual
            ;;
        5)
            test_analysis
            ;;
        6)
            test_firebase
            ;;
        7)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please choose 1-7."
            echo ""
            ;;
    esac
    
    read -p "Press Enter to continue..."
    clear
done