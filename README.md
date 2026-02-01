# Food Redistribution System (FreshSave)

A mobile application built with **Flutter** and **Firebase** to connect food donors (restaurants, grocers) with NGOs and volunteers to reduce food waste and help those in need.

## 🚀 Features

*   **Role-Based Access Control**: specialized interfaces for Donors, NGOs, Volunteers, and Admins.
*   **Food Donation Management**: Donors can list surplus food with details (expiry, type, photos).
*   **Real-time Matching**: NGOs receive notifications for available food in their vicinity.
*   **Verification System**: Document verification for organizations to ensure trust.
*   **Tracking**: Status updates for food pickup and delivery.
*   **Security**: Secure authentication and session management.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Auth, Firestore, Cloud Messaging, Storage)
*   **State Management**: Provider
*   **Navigation**: GoRouter

## 📦 Project Structure

```
food_redistribution_app/
├── android/          # Android native code
├── ios/              # iOS native code
├── lib/
│   ├── config/       # App configuration and themes
│   ├── middleware/   # RBAC and security middleware
│   ├── models/       # Data models (User, Donation, etc.)
│   ├── providers/    # State management providers
│   ├── screens/      # UI Screens organized by feature/role
│   ├── services/     # Firebase service integrations
│   ├── utils/        # Helper functions and constants
│   ├── widgets/      # Reusable UI components
│   └── main.dart     # Entry point
└── pubspec.yaml      # Dependencies
```

## ⚡ Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
*   [VS Code](https://code.visualstudio.com/) with Flutter extension.
*   A Firebase project.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/food-redistribution-system.git
    cd food-redistribution-system/food_redistribution_app
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    *   Install the Firebase CLI and FlutterFire CLI.
    *   Configure the project:
        ```bash
        flutterfire configure
        ```
    *   This generates `lib/firebase_options.dart`.

4.  **Run the App**
    ```bash
    flutter run
    ```

## 🔒 Security Note

This repository does **not** contain the `lib/firebase_options.dart` file as it stores project-specific credentials. You must generate your own using the setup steps above.

## 🤝 Contribution

Contributions are welcome! Please ensure you follow the existing code style and structure.