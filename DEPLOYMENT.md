# 🚀 Deployment Guide

## Overview

This guide covers the complete deployment process for the Food Redistribution Platform across multiple environments and platforms. The application supports deployment to mobile app stores, web hosting platforms, and desktop distribution channels.

## 📋 Prerequisites

### Development Environment
- **Flutter SDK**: 3.38.5+ (stable channel)
- **Dart SDK**: 3.10.4+
- **Android Studio**: Latest version with Android SDK
- **Xcode**: 15.0+ (for iOS deployment, macOS only)
- **Node.js**: 18+ (for web deployment tools)
- **Git**: Version control

### Platform-Specific Requirements
- **Android**: Android SDK 21+ (Android 5.0)
- **iOS**: iOS 12.0+, Xcode 15+
- **Web**: Modern browsers (Chrome 85+, Safari 14+, Firefox 80+)
- **Windows**: Windows 10 version 1903+

### Accounts and Credentials
- **Google Play Console**: Android app publishing
- **Apple Developer Account**: iOS app publishing
- **Firebase Project**: Backend services
- **Domain & Hosting**: Web deployment (optional)

## 🏗️ Build Configuration

### Environment Configuration
Create environment-specific configuration files:

```dart
// lib/config/env_config.dart
class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development'
  );
  
  static const bool isProduction = environment == 'production';
  static const bool isStaging = environment == 'staging';
  static const bool isDevelopment = environment == 'development';
  
  // API endpoints
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return 'https://api.foodredistribution.org';
      case 'staging':
        return 'https://staging-api.foodredistribution.org';
      default:
        return 'https://dev-api.foodredistribution.org';
    }
  }
  
  // Firebase configuration
  static Map<String, dynamic> get firebaseConfig {
    if (isProduction) {
      return {
        'apiKey': 'prod-api-key',
        'projectId': 'food-redistribution-prod',
        // ... production config
      };
    } else if (isStaging) {
      return {
        'apiKey': 'staging-api-key',
        'projectId': 'food-redistribution-staging',
        // ... staging config
      };
    } else {
      return {
        'apiKey': 'dev-api-key',
        'projectId': 'food-redistribution-dev',
        // ... development config
      };
    }
  }
}
```

### Build Flavors Configuration
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/config/

# Build flavors for different environments
flutter build apk --flavor production --dart-define=ENVIRONMENT=production
flutter build apk --flavor staging --dart-define=ENVIRONMENT=staging
```

## 📱 Android Deployment

### Preparation
1. **Configure signing**: Create `android/app/key.properties`
```properties
storePassword=myStorePassword
keyPassword=myKeyPassword
keyAlias=myKeyAlias
storeFile=../release-key.keystore
```

2. **Update build.gradle**: Configure signing in `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Build Process
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build APK (for testing)
flutter build apk --release --dart-define=ENVIRONMENT=production

# Build App Bundle (for Play Store)
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# Verify build
./gradlew bundleRelease --info
```

### Google Play Store Deployment
1. **Create Play Console account**
2. **Upload App Bundle**: Go to Play Console → Create App → Upload AAB file
3. **Configure store listing**:
   - App name: "Food Redistribution Platform"
   - Short description: "Connect food donors with communities in need"
   - Full description: Include features, benefits, and usage instructions
   - Screenshots: High-quality images from all device types
   - Privacy Policy URL: Required for Play Store

4. **Set up release tracks**:
   - **Internal testing**: Team and stakeholder testing
   - **Alpha**: Limited external testing
   - **Beta**: Broader testing group
   - **Production**: Public release

### Play Store Optimization
```yaml
# android/app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Food Redistribution"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:enableOnBackInvokedCallback="true">
        
        <!-- App metadata for Play Store -->
        <meta-data
            android:name="com.google.android.gms.version"
            android:value="@integer/google_play_services_version" />
    </application>
    
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
```

## 🍎 iOS Deployment

### Preparation
1. **Configure Xcode project**: Open `ios/Runner.xcworkspace`
2. **Set Bundle Identifier**: Unique identifier (e.g., `com.foodredistribution.app`)
3. **Configure signing**: Select development team and provisioning profile
4. **Update Info.plist**: Add required permissions and configurations

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <key>CFBundleName</key>
    <string>Food Redistribution</string>
    <key>CFBundleDisplayName</key>
    <string>Food Redistribution</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <!-- Location permission -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to find nearby food donations and recipients.</string>
    
    <!-- Camera permission -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos of food donations.</string>
</dict>
```

### Build Process
```bash
# Clean and prepare
flutter clean
flutter pub get

# Build iOS archive
flutter build ios --release --dart-define=ENVIRONMENT=production

# Open in Xcode for final configuration
open ios/Runner.xcworkspace
```

### App Store Connect
1. **Archive in Xcode**: Product → Archive
2. **Upload to App Store Connect**: Distribute App → App Store Connect
3. **Configure app listing**:
   - App name and description
   - Keywords for App Store search
   - Screenshots for all device sizes
   - App preview videos (recommended)
   - Privacy policy and support URLs

4. **Submit for review**:
   - Complete all required metadata
   - Ensure compliance with App Store guidelines
   - Respond to review feedback promptly

### iOS Release Checklist
- [ ] App Bundle ID configured
- [ ] Code signing certificates valid
- [ ] All device sizes tested
- [ ] Privacy policy compliance
- [ ] Location and camera permissions justified
- [ ] App Store guidelines compliance

## 🌐 Web Deployment

### Build Configuration
```bash
# Build for web
flutter build web --release --dart-define=ENVIRONMENT=production

# Build with specific base href (for subdirectory hosting)
flutter build web --base-href="/food-redistribution/" --release
```

### Firebase Hosting
1. **Install Firebase CLI**:
```bash
npm install -g firebase-tools
```

2. **Initialize Firebase hosting**:
```bash
firebase init hosting
```

3. **Configure hosting** (`firebase.json`):
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(eot|otf|ttf|ttc|woff|font.css)",
        "headers": [
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          }
        ]
      }
    ]
  }
}
```

4. **Deploy**:
```bash
flutter build web --release
firebase deploy --only hosting
```

### Alternative Web Hosting
**Netlify**:
```toml
# netlify.toml
[build]
  publish = "build/web"
  command = "flutter build web --release"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

**Vercel**:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ]
}
```

### Web Performance Optimization
```dart
// lib/main.dart - Web-specific optimizations
import 'package:flutter/foundation.dart';

void main() {
  if (kIsWeb) {
    // Enable web-specific optimizations
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(MyApp());
}
```

## 🖥️ Windows Deployment

### Build Process
```bash
# Build Windows executable
flutter build windows --release --dart-define=ENVIRONMENT=production
```

### Distribution Options
**1. Direct Distribution**:
- Zip the `build/windows/runner/Release` folder
- Include installation instructions
- Provide system requirements

**2. Windows Package Manager**:
```yaml
# winget-pkgs manifest
PackageIdentifier: FoodRedistribution.Platform
PackageVersion: 1.0.0
PackageName: Food Redistribution Platform
Publisher: Food Redistribution Team
ShortDescription: Connect food donors with communities in need
PackageUrl: https://github.com/Shravanthi20/food-redistribution-system
License: MIT
Installers:
  - Architecture: x64
    InstallerType: exe
    InstallerUrl: https://releases.foodredistribution.org/v1.0.0/setup.exe
```

**3. Microsoft Store**:
- Use MSIX packaging for Store distribution
- Configure Package.appxmanifest
- Submit through Partner Center

### MSIX Packaging
```yaml
# pubspec.yaml
msix_config:
  display_name: Food Redistribution Platform
  publisher_display_name: Food Redistribution Team
  identity_name: FoodRedistribution.Platform
  msix_version: 1.0.0.0
  description: Connect food donors with communities in need
  capabilities: 'internetClient,location,webcam'
```

```bash
# Build MSIX package
flutter pub run msix:create
```

## 🔄 CI/CD Pipeline

### GitHub Actions
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy Multi-Platform

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.5'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Setup Android signing
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 -d > android/app/release-key.keystore
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=release-key.keystore" >> android/key.properties
      - run: flutter build appbundle --release --dart-define=ENVIRONMENT=production
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.foodredistribution.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  build-ios:
    needs: test
    runs-on: macos-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Setup iOS signing
        run: |
          # Configure certificates and provisioning profiles
          echo "${{ secrets.IOS_CERTIFICATE }}" | base64 -d > certificate.p12
          echo "${{ secrets.IOS_PROVISION }}" | base64 -d > profile.mobileprovision
          security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
          security import certificate.p12 -k build.keychain -P "${{ secrets.CERTIFICATE_PASSWORD }}" -T /usr/bin/codesign
          security list-keychains -s build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
          cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
      - run: flutter build ios --release --dart-define=ENVIRONMENT=production --no-codesign
      - name: Build and upload to TestFlight
        run: |
          cd ios
          xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive
          xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath build/

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release --dart-define=ENVIRONMENT=production
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: food-redistribution-prod

  build-windows:
    needs: test
    runs-on: windows-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release --dart-define=ENVIRONMENT=production
      - run: flutter pub run msix:create
      - name: Upload Windows package
        uses: actions/upload-artifact@v3
        with:
          name: windows-msix
          path: build/windows/runner/Release/food_redistribution_app.msix
```

## 📊 Monitoring and Analytics

### Firebase Crashlytics
```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Set up Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runZonedGuarded<Future<void>>(() async {
    runApp(MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}
```

### Performance Monitoring
```dart
// lib/services/performance_service.dart
class PerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  static Future<void> trackApiCall(String endpoint) async {
    final trace = _performance.newTrace('api_call_$endpoint');
    await trace.start();
    // ... API call
    await trace.stop();
  }
  
  static void trackScreenView(String screenName) {
    FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }
}
```

## 🔧 Environment Management

### Development Environment
```bash
# Development server
flutter run -d chrome --dart-define=ENVIRONMENT=development

# Debug with specific device
flutter run -d android --debug
```

### Staging Environment
```bash
# Staging build
flutter build web --dart-define=ENVIRONMENT=staging
firebase use staging
firebase deploy --only hosting
```

### Production Environment
```bash
# Production release
flutter build appbundle --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production
flutter build web --release --dart-define=ENVIRONMENT=production
```

## 🚨 Rollback Strategy

### App Store Rollback
1. **Immediate**: Stop roll-out in console
2. **Version rollback**: Revert to previous version
3. **Hot fix**: Deploy critical fixes

### Web Rollback
```bash
# Firebase hosting rollback
firebase hosting:clone SOURCE_SITE_ID:SOURCE_VERSION_ID TARGET_SITE_ID

# Manual rollback
git revert <commit-hash>
flutter build web --release
firebase deploy --only hosting
```

### Android Rollback
1. **Play Console**: Halt release or reduce rollout percentage
2. **Emergency**: Release hotfix with higher version code
3. **Staged rollout**: Monitor metrics and adjust rollout speed

## 📋 Post-Deployment Checklist

### Immediate Verification
- [ ] App launches successfully on all platforms
- [ ] Core functionality works (authentication, main features)
- [ ] API endpoints respond correctly
- [ ] Push notifications functional
- [ ] Analytics tracking working

### Performance Monitoring
- [ ] Monitor crash rates (< 1%)
- [ ] Check app startup times
- [ ] Verify API response times
- [ ] Monitor user engagement metrics
- [ ] Track conversion funnels

### User Feedback
- [ ] Monitor app store reviews
- [ ] Check support channels for issues
- [ ] Track user retention metrics
- [ ] Analyze feature usage patterns

### Security Verification
- [ ] Verify SSL certificates
- [ ] Check API security headers
- [ ] Validate data encryption
- [ ] Confirm access controls
- [ ] Test authentication flows

---

This deployment guide ensures a smooth, reliable release process across all supported platforms. Follow the checklists and monitor the specified metrics to maintain a high-quality user experience.

## 🆘 Emergency Contacts

- **Production Issues**: production-alerts@foodredistribution.org
- **Security Issues**: security@foodredistribution.org
- **General Support**: support@foodredistribution.org

## 📚 Additional Resources

- [Flutter Deployment Documentation](https://flutter.dev/docs/deployment)
- [Firebase Hosting Guide](https://firebase.google.com/docs/hosting)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Guide](https://developer.apple.com/app-store-connect/)