# Firebase Deployment - Quick Fix

The Firebase project `ninja-tutor-44dec` may not be accessible or doesn't exist. Here's how to fix it:

## Solution: Use Firebase CLI Interactively

Run this command and follow the prompts:

```bash
firebase init hosting
```

**When prompted:**

1. **"Select a Firebase project"** - Choose "Create a new project" or select an existing one you have access to
2. **"What do you want to use as your public directory?"** - Enter: `build/web`
3. **"Configure as a single-page app?"** - Type: `Yes`
4. **"Set up automatic builds and deploys with GitHub?"** - Type: `No`

This will automatically configure `.firebaserc` and `firebase.json` correctly.

## Then Deploy

```bash
# Build the app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

## Alternative: Use a Different Hosting Service

If Firebase continues to have issues, you can deploy to other free hosting platforms:

### Option 1: Netlify (Easier)

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build
flutter build web --release

# Deploy
netlify deploy --prod --dir=build/web
```

### Option 2: Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel --prod
```

### Option 3: GitHub Pages

1. Build: `flutter build web --release`
2. Push `build/web` contents to a `gh-pages` branch
3. Enable GitHub Pages in repo settings

## Keep Using Firebase?

If you want to use Firebase, you'll need to either:

- Use your existing Firebase project from console.firebase.google.com
- Create a new Firebase project
- Get added to the `ninja-tutor-44dec` project by the owner
