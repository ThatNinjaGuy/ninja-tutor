# Ninja Tutor Deployment Guide

This guide walks you through deploying Ninja Tutor to production using Google Cloud Run and Firebase Hosting.

## Prerequisites

- Google Cloud account (with billing enabled for Cloud Run)
- Firebase project (ninja-tutor-44dec)
- Flutter SDK installed
- Google Cloud SDK (`gcloud`) installed
- Firebase CLI installed

## Step 1: Backend Deployment (Google Cloud Run)

### 1.1 Set up Google Cloud Project

```bash
# Install Google Cloud SDK if not already installed
# https://cloud.google.com/sdk/docs/install

# Authenticate with Google Cloud
gcloud auth login

# Set your project
gcloud config set project ninja-tutor-44dec

# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 1.2 Configure Environment Variables

Create a `.env` file in `ninja_tutor_backend/` with your production credentials:

```bash
cd ninja_tutor_backend
cp env_example .env
# Edit .env with your actual credentials
```

**Important**: Add production settings:

```bash
DEBUG=false
LOG_LEVEL=INFO
FIREBASE_HOSTING_URL=ninja-tutor-44dec.web.app
```

### 1.3 Deploy to Cloud Run

```bash
cd ninja_tutor_backend

# Build and deploy using Cloud Build
gcloud builds submit --config cloudbuild.yaml
```

After deployment, note the Cloud Run service URL (e.g., `https://ninja-tutor-backend-xxxxx.run.app`)

### 1.4 Update Cloud Run Environment Variables

```bash
# Set environment variables in Cloud Run
gcloud run services update ninja-tutor-backend \
  --region us-central1 \
  --set-env-vars "FIREBASE_HOSTING_URL=ninja-tutor-44dec.web.app,DEBUG=false,LOG_LEVEL=INFO"
```

## Step 2: Frontend Web Deployment (Firebase Hosting)

### 2.1 Update Backend URL

Edit `ninja_tutor/lib/core/constants/app_constants.dart`:

```dart
// Update the production URL with your actual Cloud Run URL
static const String productionBaseUrl = 'https://ninja-tutor-backend-xxxxx.run.app';

// Then uncomment this line:
return kReleaseMode ? productionBaseUrl : developmentBaseUrl;
```

And add the import at the top:

```dart
import 'package:flutter/foundation.dart';
```

### 2.2 Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 2.3 Build Flutter Web

```bash
cd ninja_tutor

# Build for production
flutter build web --release

# If you have the updated constants with kReleaseMode
# The app will automatically use the production backend URL
```

### 2.4 Deploy to Firebase Hosting

```bash
# Deploy to Firebase Hosting
firebase deploy --only hosting
```

The app will be live at: `https://ninja-tutor-44dec.web.app`

## Step 3: Mobile App Builds

### 3.1 Android Release Build

#### Create Signing Key (First time only)

```bash
cd ninja_tutor/android

# Create a keystore
keytool -genkey -v -keystore ~/ninja-tutor-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ninja-tutor

#### Configure Signing

Create `android/key.properties` (copy from example):
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=ninja-tutor
storeFile=<path-to-keystore>
```

#### Update Backend URL in App

Edit `ninja_tutor/lib/core/constants/app_constants.dart`:

```dart
// For mobile apps, you'll want to use the production URL
// or implement remote config
return productionBaseUrl;
```

#### Build Release APK/AAB

```bash
cd ninja_tutor

# Build APK
flutter build apk --release --split-per-abi

# OR build App Bundle for Google Play
flutter build appbundle --release
```

Files will be in:

- APK: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (or arm64)
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 3.2 iOS Release Build

Note: iOS builds require macOS and Xcode

```bash
cd ninja_tutor

# Build iOS (requires macOS)
flutter build ios --release

# Then open in Xcode for signing and archive
open ios/Runner.xcworkspace
```

In Xcode:

1. Select your signing team
2. Product > Archive
3. Distribute to App Store or Ad Hoc

## Step 4: Post-Deployment

### 4.1 Update CORS in Backend

Update the Cloud Run service to allow Firebase Hosting origin:

```bash
gcloud run services update ninja-tutor-backend \
  --region us-central1 \
  --update-env-vars FIREBASE_HOSTING_URL=ninja-tutor-44dec.web.app
```

### 4.2 Test the Deployment

1. Visit `https://ninja-tutor-44dec.web.app`
2. Test user registration/login
3. Test book upload and reading
4. Test AI features

### 4.3 Monitor Costs

Check Google Cloud Console and Firebase Console for usage:

- Google Cloud Run usage
- Firebase Hosting bandwidth
- Cloud Storage usage

Expected monthly cost: $0-5 for small usage

## Step 5: Custom Domain (Optional)

### 5.1 Add Custom Domain to Firebase Hosting

```bash
firebase hosting:channel:deploy production --only hosting
```

In Firebase Console:

1. Go to Hosting
2. Add custom domain
3. Follow DNS configuration instructions

### 5.2 Update CORS

Update Cloud Run to allow custom domain:

```bash
gcloud run services update ninja-tutor-backend \
  --update-env-vars FIREBASE_HOSTING_URL=your-domain.com
```

## Troubleshooting

### Backend Issues

- **502 Bad Gateway**: Check Cloud Run logs for errors
- **CORS errors**: Verify FIREBASE_HOSTING_URL is set correctly
- **Firebase auth fails**: Check Firebase credentials in .env

### Frontend Issues

- **Blank page**: Check browser console for errors
- **API calls fail**: Verify backend URL in app_constants.dart
- **Build fails**: Run `flutter clean` and rebuild

### Mobile Build Issues

- **Signing errors**: Verify key.properties exists and is correct
- **Build errors**: Check Flutter doctor for issues
- **iOS signing**: Ensure valid Apple Developer account

## Security Notes

- Never commit `.env` files or `key.properties` to git
- Keep your signing keys secure (backup safely)
- Use Google Secret Manager for sensitive environment variables
- Enable Cloud Run authentication if needed
- Set up Firebase security rules for Firestore and Storage

## Continuous Deployment

To set up automatic deployments:

1. Connect your GitHub repo to Cloud Build
2. Set up Firebase Hosting GitHub integration
3. Configure build triggers on push to main/master

See Google Cloud Build and Firebase documentation for details.

## Support

For issues or questions:

- Check Cloud Run logs: `gcloud run services logs read ninja-tutor-backend`
- Check Firebase Hosting logs: Firebase Console > Hosting > Logs
- Review application logs in Cloud Run console
