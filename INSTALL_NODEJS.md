# How to Install Node.js and Run FreshSave

## Why Node.js Cannot Be Installed in the Project

Node.js is a **runtime environment** (like Java or Python) that must be installed on your operating system, not within a project folder. It's similar to how you can't "install Windows" inside a folder - it needs to be installed system-wide.

## Quick Installation Guide

### Step 1: Download Node.js

1. **Open your browser** and go to: **https://nodejs.org/**
2. **Click the green button** that says "Download Node.js (LTS)"
   - LTS = Long Term Support (recommended for most users)
   - Current version is around v20.x or v18.x
3. **Save the installer** (it will be named something like `node-v20.x.x-x64.msi`)

### Step 2: Install Node.js

1. **Run the downloaded installer** (double-click the .msi file)
2. **Click "Next"** through the installation wizard
3. **Accept the license agreement**
4. **Keep the default installation path**: `C:\Program Files\nodejs\`
5. **Make sure these boxes are checked**:
   - ✅ Node.js runtime
   - ✅ npm package manager
   - ✅ Add to PATH
6. **Click "Install"** (may require administrator permission)
7. **Wait for installation** (takes 1-2 minutes)
8. **Click "Finish"**

### Step 3: Verify Installation

1. **Open a NEW Command Prompt or PowerShell window**
   - Press `Windows + R`
   - Type `cmd` and press Enter
   
2. **Check Node.js version**:
   ```bash
   node --version
   ```
   You should see: `v20.x.x` or similar

3. **Check npm version**:
   ```bash
   npm --version
   ```
   You should see: `10.x.x` or similar

✅ If you see version numbers, Node.js is installed correctly!

### Step 4: Run FreshSave Application

Now you can run the setup scripts:

1. **Open Command Prompt** in `c:\software_eval`
   - Navigate to the folder in File Explorer
   - Type `cmd` in the address bar and press Enter

2. **Setup Backend**:
   ```bash
   setup-backend.bat
   ```
   - This will install all backend dependencies
   - Follow the prompts to add Firebase credentials

3. **Setup Frontend** (open a NEW terminal):
   ```bash
   setup-frontend.bat
   ```
   - This will install all frontend dependencies
   - Follow the prompts to add Firebase config

4. **Start Backend** (in first terminal):
   ```bash
   cd backend
   npm run dev
   ```

5. **Start Frontend** (in second terminal):
   ```bash
   cd frontend
   npm run dev
   ```

6. **Open browser** to `http://localhost:5173`

## Troubleshooting

### "node is not recognized" after installation
- **Close and reopen** your terminal/command prompt
- Node.js adds itself to PATH, but existing terminals don't see it
- If still not working, **restart your computer**

### Installation fails
- **Run installer as Administrator**: Right-click → "Run as administrator"
- **Disable antivirus temporarily** during installation
- **Check disk space**: Need at least 500MB free

### Need older version?
- Visit: https://nodejs.org/en/download/releases/
- Download v18.x LTS if v20 has issues

## Alternative: Use the Browser Demo

While you install Node.js, you can see the full UI by opening:

**`c:\software_eval\interactive-demo.html`**

This shows all the registration forms and interactions in your browser right now, without needing Node.js!

## Why You Need Node.js

- **npm**: Package manager to install React, Express, etc.
- **Build tools**: Vite needs Node.js to run the dev server
- **Backend**: Express server runs on Node.js
- **Development**: Hot reload, debugging, etc.

## Estimated Time

- **Download**: 1-2 minutes (depending on internet speed)
- **Install**: 2-3 minutes
- **Setup project**: 5-10 minutes (downloading dependencies)
- **Total**: ~15 minutes to get everything running

## Still Having Issues?

If you encounter problems:
1. Check the official guide: https://nodejs.org/en/download/package-manager/
2. Try the Windows installer troubleshooting: https://docs.npmjs.com/try-the-latest-stable-version-of-node
3. Consider using Node Version Manager (nvm-windows): https://github.com/coreybutler/nvm-windows
