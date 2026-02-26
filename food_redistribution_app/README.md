# Food Redistribution Platform - Flutter App

A comprehensive Flutter application for food redistribution and waste reduction, implementing Module 1 (User Authentication & Role Management) and Module 2 (Food Donation Management).

## Project Structure

```
food_redistribution_app/
├── lib/
│   ├── models/                 # Data models
│   │   ├── user.dart          # User and role models
│   │   ├── donor_profile.dart # Donor profile model
│   │   ├── ngo_profile.dart   # NGO profile model
│   │   ├── volunteer_profile.dart # Volunteer profile model
│   │   └── food_donation.dart # Food donation model
│   ├── services/              # Business logic services
│   │   ├── auth_service.dart  # Authentication service
│   │   ├── user_service.dart  # User management service
│   │   └── food_donation_service.dart # Food donation management
│   ├── providers/             # State management
│   │   ├── auth_provider.dart # Authentication provider
│   │   └── user_provider.dart # User data provider
│   ├── screens/               # UI screens
│   │   ├── auth/             # Authentication screens
│   │   ├── donor/            # Donor-specific screens
│   │   ├── ngo/              # NGO-specific screens
│   │   ├── volunteer/        # Volunteer-specific screens
│   │   └── admin/            # Admin screens
│   ├── widgets/               # Reusable UI components
│   ├── utils/                 # Utilities and configurations
│   └── main.dart              # App entry point
└── pubspec.yaml               # Dependencies
```

## Features Implemented

### Module 1: User Authentication & Role Management

#### User Stories Implemented:

- **US1**: Secure Donor Registration with role tagging, OTP/email verification, and secure credential storage
- **US2**: NGO Organization Registration with admin approval workflow
- **US3**: Volunteer Account Creation and profile activation
- **US4**: Robust authentication with password strength rules, session management, and brute-force protection
- **US5**: Secure account recovery with password reset functionality
- **US6**: Admin verification of NGO and donor certificates
- **US7**: Role-based access control enforcement
- **US8**: Auditable verification and administrative actions
- **US9**: Temporary role restriction and permission suspension
- **US10**: Role-specific onboarding state management

#### Key Features:
- Firebase Authentication integration
- Role-based user registration (Donor, NGO, Volunteer, Admin)
- Email verification workflow
- Secure password management
- Role-based access control (RBAC)
- Admin user verification system
- Audit logging for security
- Temporary user restrictions
- Onboarding state management

### Module 2: Food Donation Management

#### User Stories Implemented:

- **US8**: Food donation posting with safety validation
- **US9**: Donation update/cancellation before pickup
- **US11**: NGO food requirements specification
- **US12**: NGO donation review and acceptance with hygiene compliance
- **US14**: Clarification requests between NGOs and donors
- **US15**: Traceability of hygiene and acceptance decisions

#### Key Features:
- Food donation creation and management
- Safety time window validation
- NGO food requirement matching
- Hygiene and safety compliance checking
- Donation status tracking
- NGO-donor clarification system
- Comprehensive audit trails

## Tech Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider pattern
- **UI**: Material Design 3
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage

## Dependencies

Key Flutter packages used:
- `firebase_core` & `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `provider` - State management
- `google_fonts` - Typography
- `go_router` - Navigation
- `flutter_form_builder` - Form handling
- `image_picker` - Image selection
- `geolocator` - Location services

## Setup Instructions

### Prerequisites

1. Flutter SDK (3.0 or higher)
2. Firebase project with the following services enabled:
   - Authentication
   - Cloud Firestore
   - Storage
3. Android Studio or VS Code

### Firebase Configuration

1. Create a new Firebase project at https://console.firebase.google.com
2. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Storage

3. Configure Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Profile documents
    match /donor_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'ngo'];
    }
    
    match /ngo_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'donor'];
    }
    
    match /volunteer_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Food donations
    match /food_donations/{donationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'donor';
      allow update: if request.auth != null && (
        resource.data.donorId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'ngo', 'volunteer']
      );
    }
    
    // Admin only collections
    match /audit_logs/{document} {
      allow read, write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /review_queue/{document} {
      allow read, write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

4. Update `lib/firebase_options.dart` with your project configuration
5. Download `google-services.json` for Android and `GoogleService-Info.plist` for iOS

### Installation

1. Clone the repository and navigate to the Flutter project:
```bash
cd food_redistribution_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update Firebase configuration in `lib/firebase_options.dart`

4. Run the app:
```bash
flutter run
```

## User Roles and Permissions

### Donor
- Create and manage food donations
- Update donation details before pickup
- View own donation history
- Respond to clarification requests

### NGO
- Browse available food donations
- Set food requirements and preferences
- Review and accept/reject donations
- Request clarifications from donors
- Manage multiple branches

### Volunteer
- View assigned pickup/delivery tasks
- Update delivery status
- Access optimized route information

### Admin
- Verify user registrations
- Manage user permissions
- View system-wide analytics
- Access audit logs
- Handle appeals and restrictions

## Database Schema

### Collections

1. **users** - Core user information
2. **donor_profiles** - Donor-specific data
3. **ngo_profiles** - NGO organization data
4. **volunteer_profiles** - Volunteer information
5. **food_donations** - Food donation listings
6. **food_requests** - NGO food requirements
7. **audit_logs** - System action logs
8. **review_queue** - Pending user verifications
9. **clarification_requests** - NGO-Donor communications

## Security Features

- Firebase Authentication with email verification
- Role-based access control (RBAC)
- Input validation and sanitization
- Secure password requirements
- Session management
- Comprehensive audit logging
- User restriction mechanisms

## Next Steps for Full Implementation

1. Complete remaining UI screens
2. Implement Module 3 (Volunteer Assignment)
3. Add Module 4 (Real-time Tracking)
4. Implement Module 5 (Multilingual Support)
5. Add push notifications
6. Implement offline capabilities
7. Add comprehensive testing
8. Performance optimization
9. Production deployment

## Contributing

This is a comprehensive food redistribution platform designed to reduce food waste and help communities in need. The current implementation covers the core authentication and food donation management features, providing a solid foundation for the complete system.

## License

This project is developed for social impact and food waste reduction initiatives.