# 🔥 Firebase Setup Guide

## Phase 1 & 2 Complete! ✅

You've successfully completed the implementation of:
- ✅ **Phase 1**: Core Authentication & Onboarding (Login, Registration, Email Verification)
- ✅ **Phase 2**: Donor Features (Create/Edit/List/Cancel Donations + Impact Reports)

## 🚨 Required: Firebase Configuration

Before you can test the app, you need to set up Firebase. Here's the complete process:

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"**
3. Enter project name: `food-redistribution-app` (or your preferred name)
4. Disable Google Analytics (optional for development)
5. Click **"Create Project"**

---

## Step 2: Enable Firebase Services

### Authentication
1. In Firebase Console, go to **Build → Authentication**
2. Click **"Get Started"**
3. Enable **Email/Password** sign-in method
4. (Optional) Enable **Google Sign-In** for social login

### Firestore Database
1. Go to **Build → Firestore Database**
2. Click **"Create Database"**
3. Select **"Start in test mode"** (for development)
4. Choose your preferred location (e.g., us-central)
5. Click **"Enable"**

### Storage
1. Go to **Build → Storage**
2. Click **"Get Started"**
3. Start in **test mode**
4. Click **"Done"**

### Cloud Messaging (for notifications)
1. Go to **Build → Cloud Messaging**
2. Click **"Get Started"**
3. No additional setup needed at this stage

---

## Step 3: Add Android App

1. In Firebase Console, click the **Android icon** to add Android app
2. Enter Android package name: `com.example.food_redistribution_app`
   - Find this in `android/app/build.gradle.kts` (look for `applicationId`)
3. (Optional) Enter app nickname: "Food Redistribution App"
4. Click **"Register app"**
5. **Download `google-services.json`**
6. Place the downloaded file in: `android/app/google-services.json`

### Verify Android Configuration

Check that `android/app/build.gradle.kts` has these plugins:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Should be present
}
```

And dependencies include:
```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
}
```

---

## Step 4: Add iOS App (Optional - if testing on iOS)

1. In Firebase Console, click the **iOS icon**
2. Enter iOS bundle ID: `com.example.foodRedistributionApp`
   - Find this in `ios/Runner.xcodeproj/project.pbxproj` (look for `PRODUCT_BUNDLE_IDENTIFIER`)
3. Download `GoogleService-Info.plist`
4. Open Xcode: `open ios/Runner.xcworkspace`
5. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
6. Ensure "Copy items if needed" is checked

---

## Step 5: Update Firebase Options

Run the FlutterFire CLI to automatically configure:

```bash
# Install FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will:
- Detect your Firebase project
- Update `lib/firebase_options.dart` with real credentials
- Configure all platforms (Android, iOS, Web)

**Alternatively**, manually update `lib/firebase_options.dart`:
1. Go to Firebase Console → Project Settings → General
2. Copy your project configuration values
3. Replace placeholder values in `firebase_options.dart`

---

## Step 6: Set Firestore Security Rules

In Firebase Console → Firestore Database → Rules, paste these starter rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update, delete: if isAuthenticated() && isOwner(userId);
    }
    
    // Donations collection
    match /donations/{donationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.donorId == request.auth.uid;
      allow update: if isAuthenticated() && 
        (resource.data.donorId == request.auth.uid || 
         resource.data.claimedByNGO == request.auth.uid);
      allow delete: if isAuthenticated() && resource.data.donorId == request.auth.uid;
    }
    
    // NGO Profiles
    match /ngo_profiles/{ngoId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isOwner(ngoId);
      allow delete: if isAuthenticated() && isOwner(ngoId);
    }
    
    // Volunteer Profiles
    match /volunteer_profiles/{volunteerId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isOwner(volunteerId);
      allow delete: if isAuthenticated() && isOwner(volunteerId);
    }
    
    // Donor Profiles
    match /donor_profiles/{donorId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated() && isOwner(donorId);
      allow delete: if isAuthenticated() && isOwner(donorId);
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Step 7: Set Storage Security Rules

In Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /donations/{donationId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Step 8: Test the Configuration

1. Clean and rebuild your project:
```bash
flutter clean
flutter pub get
```

2. Run the app:
```bash
flutter run
```

3. Test the flow:
   - Register a new donor account
   - Verify email (check console/logs for verification link in dev mode)
   - Login with the account
   - Create a donation
   - View donations list
   - Check impact reports

---

## Troubleshooting

### "No Firebase App has been created"
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean && flutter pub get`
- Rebuild the app

### "Invalid API Key" or "Project Not Found"
- Re-run `flutterfire configure`
- Verify `firebase_options.dart` has correct project ID

### "Permission Denied" on Firestore
- Check Firestore security rules
- Ensure user is authenticated before operations

### Build fails with "google-services plugin"
- Check `android/build.gradle.kts` has the Google services classpath
- Ensure `android/app/build.gradle.kts` applies the plugin

---

## Next Steps

Once Firebase is configured and working:

1. **Test Phase 1 & 2 features thoroughly**
   - User registration (Donor, NGO, Volunteer)
   - Email verification
   - Login/Logout
   - Donor: Create/Edit/Cancel donations
   - Donor: View impact reports

2. **Choose what to implement next**:
   - **Phase 3**: NGO Features (browse/claim donations, beneficiary management)
   - **Phase 4**: Volunteer Features (task management, delivery tracking)
   - **Phase 5**: Admin Features (user management, platform monitoring)
   - **Phase 6**: Real-time Features (live tracking, chat, notifications)
   - **Phase 7**: Advanced Features (AI matching, route optimization, analytics)

---

## Manual Work Required

- [ ] Create Firebase project
- [ ] Enable Authentication (Email/Password)
- [ ] Enable Firestore Database
- [ ] Enable Storage
- [ ] Download `google-services.json` → place in `android/app/`
- [ ] Download `GoogleService-Info.plist` → add to iOS (if testing iOS)
- [ ] Run `flutterfire configure` OR manually update `firebase_options.dart`
- [ ] Set Firestore security rules
- [ ] Set Storage security rules
- [ ] Test registration and login

---

## Questions?

Let me know:
1. If you encounter any Firebase setup issues
2. Which phase (3-7) you'd like me to implement next
3. If you need help with any specific feature

I'm ready to continue building once Firebase is configured! 🚀
