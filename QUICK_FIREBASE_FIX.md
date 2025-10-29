# Quick Firebase Deployment Fix

Your Firebase authentication has expired. Here's how to fix it:

## Step 1: Re-authenticate with Firebase

```bash
firebase login
```

This will open a browser for you to log in. After logging in, you'll be authenticated.

## Step 2: Initialize Firebase Hosting

```bash
firebase init hosting
```

Follow the prompts:

1. Select an existing project or create a new one
2. Public directory: `build/web`
3. Configure as single-page app: `Yes`
4. Set up automatic builds: `No`

## Step 3: Build and Deploy

```bash
# Build Flutter web
flutter build web --release

# Deploy
firebase deploy --only hosting
```

---

## If You Don't Want to Use Firebase

You can deploy to other platforms instead. See `FIREBASE_DEPLOY_FIX.md` for alternatives like Netlify or Vercel.
