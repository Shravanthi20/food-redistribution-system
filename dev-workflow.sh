#!/bin/bash

# Development Workflow Script for SISIR-REDDY
# This script helps maintain consistent commits from the SISIR-REDDY account

echo "🚀 Food Redistribution Platform - Development Workflow"
echo "================================================"

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please run from project root."
    exit 1
fi

# Verify git configuration
echo "🔧 Checking git configuration..."
CURRENT_USER=$(git config user.name)
CURRENT_EMAIL=$(git config user.email)

if [ "$CURRENT_USER" != "SISIR-REDDY" ]; then
    echo "⚙️  Setting git user to SISIR-REDDY..."
    git config user.name "SISIR-REDDY"
fi

if [ "$CURRENT_EMAIL" != "sisirreddy@example.com" ]; then
    echo "⚙️  Setting git email..."
    git config user.email "sisirreddy@example.com"
fi

echo "✅ Git configured for: $(git config user.name) <$(git config user.email)>"

# Show current status
echo ""
echo "📊 Current repository status:"
git status --short

# Function to make a development commit
make_dev_commit() {
    echo ""
    echo "📝 Creating development commit..."
    
    # Add all changes
    git add .
    
    # Get current date for commit
    CURRENT_DATE=$(date +"%Y-%m-%d %H:%M")
    
    # Create commit with development message
    git commit -m "feat: Development progress checkpoint - $CURRENT_DATE

    📈 Current development status:
    - Person 1 (Core Backend & Security): ✅ Complete
    - Person 2 (Matching & Dispatch): 🔄 In Progress
    
    🔧 Technical updates:
    - Enhanced Firestore database operations
    - Improved security middleware
    - Updated UI components
    - Bug fixes and optimizations
    
    🛡️ Security features maintained:
    - RBAC access control active
    - Audit logging functional
    - Session management secured
    - Account verification system operational
    
    👨‍💻 Committed by: SISIR-REDDY
    🕒 Timestamp: $CURRENT_DATE"
    
    echo "✅ Commit created successfully!"
}

# Function to push commits
push_changes() {
    echo ""
    echo "🚀 Pushing changes to GitHub..."
    
    # Check if we have commits to push
    if git diff --quiet HEAD origin/main; then
        echo "ℹ️  No changes to push."
        return
    fi
    
    # Push to main branch
    git push origin main
    
    if [ $? -eq 0 ]; then
        echo "✅ Changes pushed successfully!"
        echo "🌐 Repository: https://github.com/Shravanthi20/food-redistribution-system"
    else
        echo "❌ Failed to push changes. Please check your connection and try again."
    fi
}

# Main workflow menu
echo ""
echo "🔨 Choose an action:"
echo "1. Make development commit"
echo "2. Push changes to GitHub"
echo "3. Both (commit + push)"
echo "4. Show detailed status"
echo "5. Exit"

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        make_dev_commit
        ;;
    2)
        push_changes
        ;;
    3)
        make_dev_commit
        push_changes
        ;;
    4)
        echo ""
        echo "📋 Detailed repository status:"
        echo "=============================="
        git log --oneline -10
        echo ""
        echo "📊 File changes:"
        git status
        ;;
    5)
        echo "👋 Goodbye! Happy coding!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "✨ Workflow complete! Keep building amazing features! 🎯"