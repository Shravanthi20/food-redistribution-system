# FreshSave - Complete Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Node.js** (v18 or higher) - [Download here](https://nodejs.org/)
2. **MongoDB** - Either:
   - Local installation: [Download here](https://www.mongodb.com/try/download/community)
   - Cloud (MongoDB Atlas): [Sign up here](https://www.mongodb.com/cloud/atlas)
3. **Firebase Account** - [Create account](https://console.firebase.google.com/)

## Step 1: Firebase Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "FreshSave" (or your preferred name)
4. Disable Google Analytics (optional)
5. Click "Create project"

### Enable Authentication Methods
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following:
   - **Email/Password** - Click Enable and Save
   - **Google** - Click Enable, add support email, Save
   - **Apple** - Click Enable, configure Apple Developer settings, Save

### Get Firebase Config (Frontend)
1. Go to **Project Settings** (gear icon) → **General**
2. Scroll to "Your apps" section
3. Click the **Web** icon (`</>`)
4. Register app with nickname "FreshSave Web"
5. Copy the `firebaseConfig` object
6. Open `frontend/src/firebase/config.js`
7. Replace the placeholder config with your actual config

### Get Firebase Admin SDK (Backend)
1. Go to **Project Settings** → **Service Accounts**
2. Click **"Generate new private key"**
3. Save the JSON file as `serviceAccountKey.json`
4. Move it to the `backend/` folder

## Step 2: MongoDB Setup

### Option A: MongoDB Atlas (Cloud - Recommended)
1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free account
3. Create a new cluster (free tier is fine)
4. Click "Connect" → "Connect your application"
5. Copy the connection string
6. Replace `<password>` with your database password
7. Example: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/freshsave?retryWrites=true&w=majority`

### Option B: Local MongoDB
1. Install MongoDB locally
2. Start MongoDB service
3. Connection string: `mongodb://localhost:27017/freshsave`

## Step 3: Backend Setup

1. Open terminal and navigate to backend:
   ```bash
   cd c:\software_eval\backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create/Update `.env` file with your credentials:
   ```env
   PORT=5000
   MONGODB_URI=your_mongodb_connection_string_here
   FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
   ```

4. Verify `serviceAccountKey.json` is in the backend folder

5. Start the backend server:
   ```bash
   npm run dev
   ```

   You should see:
   ```
   Server running on port 5000
   Connected to MongoDB
   ```

## Step 4: Frontend Setup

1. Open a NEW terminal and navigate to frontend:
   ```bash
   cd c:\software_eval\frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Update Firebase config in `src/firebase/config.js` with your actual Firebase credentials

4. Start the development server:
   ```bash
   npm run dev
   ```

   You should see:
   ```
   VITE v6.x.x  ready in xxx ms
   ➜  Local:   http://localhost:5173/
   ```

5. Open your browser to `http://localhost:5173/`

## Step 5: Testing the Application

### Test User Registration Flow

1. **Welcome Page**: You should see three cards (Volunteer, NGO, Donor)
2. **Click on Volunteer**: Navigate to volunteer registration form
3. **Fill out the form**:
   - Full Name: Test User
   - Email: test@example.com
   - Password: test123456
   - Phone: +1234567890
   - City: New York
   - Select availability days
   - Choose transportation option
   - Add emergency contact

4. **Click "Register as Volunteer"**
   - Firebase will create the user account
   - Backend will sync user data to MongoDB
   - You'll see a success message

5. **Test Login**:
   - Go back to home and click "Log In"
   - Enter your email and password
   - You should be redirected to the dashboard

### Test Social Authentication

1. Click "Continue with Google"
2. Select your Google account
3. Grant permissions
4. You should be logged in and redirected to dashboard

## Troubleshooting

### Backend Issues

**Error: "npm is not recognized"**
- Solution: Install Node.js from nodejs.org

**Error: "Cannot find module 'express'"**
- Solution: Run `npm install` in the backend folder

**Error: "MongoDB connection failed"**
- Solution: Check your MONGODB_URI in .env file
- Ensure MongoDB is running (if local)
- Check network access in MongoDB Atlas

**Error: "Firebase Admin SDK error"**
- Solution: Verify serviceAccountKey.json is in the correct location
- Check the path in .env file

### Frontend Issues

**Error: "Firebase: Error (auth/invalid-api-key)"**
- Solution: Update firebase/config.js with correct Firebase credentials

**Error: "Network request failed"**
- Solution: Ensure backend is running on port 5000
- Check CORS settings in backend/server.js

**Blank page or white screen**
- Solution: Open browser console (F12) to see errors
- Ensure all dependencies are installed

## Production Deployment

### Backend (Node.js)
- Deploy to: Heroku, Railway, Render, or AWS
- Set environment variables in hosting platform
- Upload serviceAccountKey.json securely

### Frontend (React)
- Build: `npm run build` in frontend folder
- Deploy to: Vercel, Netlify, or Firebase Hosting
- Update API endpoint to production backend URL

## Security Notes

⚠️ **Important**:
- Never commit `serviceAccountKey.json` to Git
- Never commit `.env` files to Git
- Add both to `.gitignore`
- Use environment variables for all secrets
- Enable Firebase security rules for production

## Need Help?

If you encounter any issues:
1. Check the browser console (F12) for errors
2. Check the backend terminal for error messages
3. Verify all credentials are correct
4. Ensure both backend and frontend are running
5. Check that ports 5000 and 5173 are not in use by other applications
