# FreshSave - Food Rescue Platform

A professional multi-user registration system for a food rescue platform, built with the MERN stack and Firebase authentication.

## 🌟 Features

- **Multi-User System**: Separate registration flows for Volunteers, NGOs, and Donors
- **Firebase Authentication**: Email/Password, Google, and Apple sign-in
- **Professional UI**: Clean, modern design inspired by "Too Good To Go"
- **Responsive Design**: Works perfectly on mobile, tablet, and desktop
- **Type-Safe Forms**: Comprehensive validation and error handling
- **Secure Backend**: MongoDB storage with Firebase token verification

## 🚀 Quick Start

### Prerequisites
- Node.js (v18+)
- MongoDB (local or Atlas)
- Firebase account

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd /d "%~dp0"
   ```

2. **Setup Backend**
   ```bash
   # Run the setup script
   setup-backend.bat
   
   # Or manually:
   cd backend
   npm install
   # Add serviceAccountKey.json
   # Update .env with MongoDB URI
   npm run dev
   ```

3. **Setup Frontend** (in a new terminal)
   ```bash
   # Run the setup script
   setup-frontend.bat
   
   # Or manually:
   cd frontend
   npm install
   # Update src/firebase/config.js
   npm run dev
   ```

4. **Open browser to** `http://localhost:5173`

## 📖 Full Setup Guide

See [SETUP_GUIDE.md](./SETUP_GUIDE.md) for detailed instructions including:
- Firebase project setup
- MongoDB configuration
- Troubleshooting common issues
- Production deployment

## 🏗️ Project Structure

```
c:\software_eval\
├── backend/              # Node.js/Express API
│   ├── models/          # MongoDB schemas
│   ├── routes/          # API endpoints
│   ├── middleware/      # Auth middleware
│   └── server.js        # Entry point
│
├── frontend/            # React/Vite app
│   ├── src/
│   │   ├── pages/      # Page components
│   │   ├── components/ # Reusable components
│   │   └── firebase/   # Firebase config
│   └── package.json
│
├── SETUP_GUIDE.md      # Detailed setup instructions
└── README.md           # This file
```

## 👥 User Types

### Volunteer
Register to help rescue and distribute food with fields for availability, transportation, and emergency contacts.

### NGO
Organizations can register with details about capacity, operating hours, and services provided.

### Donor
Restaurants, stores, and individuals can register to donate surplus food with pickup/delivery options.

## 🔐 Security

- Firebase Authentication for secure user management
- Token-based API authentication
- Environment variables for sensitive data
- MongoDB for encrypted data storage

## 🛠️ Tech Stack

- **Frontend**: React, Vite, React Router, Framer Motion
- **Backend**: Node.js, Express, MongoDB, Mongoose
- **Authentication**: Firebase Auth (Email, Google, Apple)
- **Styling**: Custom CSS with design system
- **Icons**: Lucide React

## 📝 License

This project is created for educational purposes.

## 🤝 Support

For issues or questions, refer to the [SETUP_GUIDE.md](./SETUP_GUIDE.md) troubleshooting section.
