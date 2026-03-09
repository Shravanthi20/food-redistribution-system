#!/bin/bash

echo "Installing Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Downloading Dependencies..."
flutter pub get

echo "Building App for Web..."
flutter build web --no-wasm-dry-run

echo "Copying Routing Configuration..."
cp vercel.json build/web/
