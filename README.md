# Food Redistribution Platform

A comprehensive Flutter application for reducing food waste and improving food distribution to those in need.

## 🎯 Project Overview

This platform connects food donors (restaurants, grocery stores, caterers) with NGOs and volunteers to efficiently redistribute surplus food, reducing waste while feeding communities.

## 🏗️ Architecture

### **Backend: Firebase + Firestore**
- **Authentication**: Firebase Auth with email/password
- **Database**: Firestore for real-time data
- **Security**: RBAC, audit logging, session management
- **No Storage**: Text-based verification system

### **Frontend: Flutter**
- **Platform**: Cross-platform (Mobile, Web, Desktop)
- **UI**: Material Design 3
- **State Management**: Provider pattern
- **Navigation**: GoRouter

## 👥 User Roles

### **🏢 Donors (Businesses)**
- Register surplus food donations
- Manage donation lifecycle
- Track impact analytics
- Business verification system

### **🏥 NGOs (Organizations)**
- Browse and claim food donations
- Manage distribution logistics
- Coordinate with volunteers
- Service area management

### **👨‍💼 Volunteers**
- Accept pickup/delivery tasks
- Real-time location tracking
- Rating and feedback system
- Availability scheduling

### **👮‍♀️ Admins**
- User verification and management
- System oversight and analytics
- Security monitoring
- Role-based access control

## 🛡️ Security Features

- **RBAC Middleware**: Role-based access control
- **Audit Logging**: Comprehensive security tracking
- **Session Management**: Secure authentication flow
- **Brute-force Protection**: Account lockout system
- **Document Verification**: Text-based verification workflow

## 📊 Core Modules

### **Module 1: User Authentication & Role Management**
- ✅ Secure registration/login for all user types
- ✅ Role-based access control (RBAC)
- ✅ Email verification & password recovery
- ✅ Account suspension system
- ✅ Admin approval workflow

### **Module 2: Food Donation Management**
- ✅ Donation creation and lifecycle tracking
- ✅ Status management (available → reserved → completed)
- ✅ NGO assignment system
- ✅ Volunteer coordination
- ✅ Real-time notifications

## 🔧 Technical Stack

**Frontend:**
- Flutter 3.0+
- Provider (State Management)
- GoRouter (Navigation)
- Material Design 3
- Form Builder & Validators

**Backend:**
- Firebase Authentication
- Cloud Firestore
- Firebase Analytics
- Firebase Messaging

**Security & Monitoring:**
- Audit Service with risk levels
- Session management
- Device info tracking
- Security alerts system

## 📱 Installation

1. **Prerequisites**
   ```bash
   flutter --version  # Ensure Flutter 3.0+
   dart --version     # Ensure Dart 3.0+
   ```

2. **Firebase Setup**
   - Create Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download configuration files

3. **Install Dependencies**
   ```bash
   cd food_redistribution_app
   flutter pub get
   ```

4. **Run Application**
   ```bash
   flutter run -d windows  # Or your preferred platform
   ```

## 🏃‍♀️ Getting Started

### **For Development:**
1. Configure Firebase project credentials
2. Update `lib/firebase_options.dart`
3. Run `flutter run` to start development server
4. Access admin dashboard for user management

### **For Testing:**
1. Register test users for each role
2. Complete verification workflow
3. Test donation creation and assignment
4. Verify security features (failed logins, RBAC)

## 📂 Project Structure

```
food_redistribution_app/
├── lib/
│   ├── config/
│   │   └── firestore_schema.dart      # Database structure
│   ├── middleware/
│   │   └── rbac_middleware.dart       # Access control
│   ├── models/
│   │   ├── user.dart                  # User data models
│   │   ├── food_donation.dart         # Donation models
│   │   └── *_profile.dart             # Role-specific profiles
│   ├── services/
│   │   ├── auth_service.dart          # Authentication
│   │   ├── firestore_service.dart     # Database operations
│   │   ├── security_service.dart      # Security & sessions
│   │   ├── audit_service.dart         # Audit logging
│   │   ├── verification_service.dart  # Document verification
│   │   └── user_service.dart          # User management
│   ├── screens/
│   │   ├── auth/                      # Login/Register screens
│   │   ├── dashboard/                 # Role-based dashboards
│   │   ├── admin/                     # Admin interface
│   │   └── verification/              # Verification flows
│   └── providers/
│       ├── auth_provider.dart         # Auth state management
│       └── user_provider.dart         # User state management
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

## 🔐 Security Implementation

### **Person 1 Deliverables (✅ Complete):**
- **Auth Service**: Secure Firebase authentication
- **RBAC Middleware**: Route and widget protection
- **Audit Log Service**: Comprehensive event tracking
- **Verified-User Trust Layer**: Document verification system

### **Security Features:**
- Failed login protection (5 attempts = 15min lockout)
- Session timeout and management
- Device info tracking
- Risk-based audit logging
- Admin oversight dashboard

## 🚀 Deployment

### **Development**
```bash
flutter run -d chrome     # Web development
flutter run -d windows    # Desktop development
flutter run -d android    # Mobile development
```

### **Production**
```bash
flutter build web --release
flutter build windows --release
flutter build apk --release
```

## 📈 Analytics & Monitoring

- User registration and verification rates
- Food donation success metrics
- Security event monitoring
- System performance tracking
- Real-time notification delivery

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in this repository
- Contact the development team
- Check the documentation in `/docs`

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI components
- Community contributors

---

**Built with ❤️ for reducing food waste and feeding communities**