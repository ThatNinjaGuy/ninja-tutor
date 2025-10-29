# Frontend Web Deployment Instructions

## Step 1: Initialize Firebase (First Time Only)

If you haven't set up Firebase Hosting before, run:

```bash
cd ninja_tutor
firebase init hosting
```

**When prompted:**

1. Select "Use an existing project" or "Create a new project"
2. If using existing, choose your Firebase project
3. For public directory, enter: `build/web`
4. Configure as single-page app: **Yes**
5. Set up automatic builds: **No**

This will create/update your `.firebaserc` file.

## Step 2: Build Flutter Web

```bash
cd ninja_tutor

# Clean previous builds
flutter clean

# Build for production
flutter build web --release
```

## Step 3: Deploy

```bash
firebase deploy --only hosting
```

Your app will be live at `https://YOUR-PROJECT-ID.web.app`

## Troubleshooting

### "Invalid project selection" error

This means the project in `.firebaserc` doesn't exist or you don't have access.

**Solution 1:** Initialize Firebase properly

```bash
firebase init hosting
# Select "Create a new project" or choose an existing one
```

**Solution 2:** Use your existing Firebase project
Check your Firebase Console (<https://console.firebase.google.com>) for your project ID, then:

```bash
firebase use YOUR-PROJECT-ID
```

**Solution 3:** Deploy without initializing (uses default project)

```bash
firebase deploy --only hosting --project YOUR-PROJECT-ID
```

### "Assertion failed: resolving hosting target"

This happens when Firebase CLI can't determine which site to deploy to.

**Solution:** Run `firebase init hosting` and complete the setup.

### Missing build/web directory

Make sure you've run `flutter build web --release` first. The build output goes to `build/web/`.

## Alternative: Manual File Upload

If Firebase CLI continues to have issues, you can manually upload the build files:

1. Run `flutter build web --release`
2. Compress the `build/web` folder
3. Go to Firebase Console > Hosting
4. Upload the files manually
