# EPUB Viewer Troubleshooting Guide

## Changes Made

I've made several improvements to help debug and fix the EPUB rendering issue:

### 1. Fixed `pubspec.yaml` Configuration

**Problem**: The `web/` directory was incorrectly listed in the `assets` section.

- **Solution**: Commented out the assets configuration. Flutter web serves files from the `web/` directory directly at the root URL path.

### 2. Added Comprehensive Debugging

#### In `reading_viewer.dart`

- Added detailed logging for EPUB detection and loading
- Shows file URL, format, and loading progress
- Logs blob creation, data URI conversion, and iframe communication
- Added error handling for HTTP errors during EPUB fetch
- Added support for 'bookReady' message from EPUB viewer
- Added support for 'error' messages from the viewer

#### In `custom_epub_viewer.html`

- Added validation for EPUB.js library loading
- Added checks for JSZip dependency
- Better error messages sent to Flutter
- Logs URL type and length for debugging

### 3. Created Test Page

**Location**: `/web/epubjs/test_epub_viewer.html`

- Standalone test page to verify EPUB.js works independently
- Tests library loading and EPUB rendering
- Uses a public sample EPUB for testing

## How to Test

### Step 1: Test EPUB Viewer Independently

1. Start the Flutter web server:

```bash
cd /Users/deadshot/Desktop/Code/ninja-tutor/ninja_tutor
flutter run -d web-server --web-port 3000
```

2. Open the test page in your browser:

```
http://localhost:3000/epubjs/test_epub_viewer.html
```

3. Click "Test Libraries" - should show:
   - ✅ JSZip available: YES
   - ✅ EPUB.js available: YES
   - ✅ ePub function: YES

4. Click "Load Sample EPUB" - should load a sample book

### Step 2: Test with Your EPUB Files

1. Make sure your EPUB books are properly stored in the backend
2. Verify the backend is serving EPUB files with correct MIME type:
   - Check backend logs when accessing: `http://localhost:8000/api/v1/books/{book_id}/file`
   - Should show: "📕 Detected EPUB format" and media_type: "application/epub+zip"

3. Open your app and select an EPUB book from the library
4. Check the browser console (F12) for debug messages:
   - Look for "📕" emoji messages (EPUB-specific logs)
   - Look for "📖" emoji messages (general viewer logs)
   - Look for "❌" emoji messages (errors)

### Step 3: Check Common Issues

#### Issue 1: EPUB.js Library Not Loading

**Symptoms**: Console shows "EPUB.js library not loaded"
**Solution**: Check internet connection (EPUB.js loads from CDN)

#### Issue 2: Iframe Not Loading

**Symptoms**: No "✅ EPUB iframe loaded successfully" message
**Solution**:

- Verify file exists: `/web/epubjs/web/custom_epub_viewer.html`
- Check browser console for 404 errors
- Try accessing directly: `http://localhost:3000/epubjs/web/custom_epub_viewer.html`

#### Issue 3: Data URI Too Large

**Symptoms**: Error about data URI size or memory issues
**Solution**: Large EPUB files (>50MB) may have issues with data URIs. Consider:

- Using blob URLs instead of data URIs
- Implementing streaming for large files
- Splitting large EPUB files

#### Issue 4: CORS or Security Errors

**Symptoms**: Console shows CORS or X-Frame-Options errors
**Solution**: Ensure backend allows iframe embedding

## Debugging Console Commands

Open browser console (F12) and run:

```javascript
// Check if EPUB viewer iframe exists
document.querySelector('iframe[src*="epub"]')

// Check if EPUB.js is loaded in iframe
document.querySelector('iframe[src*="epub"]')?.contentWindow?.ePub

// Listen for messages from iframe
window.addEventListener('message', (e) => console.log('Message:', e.data));
```

## Expected Console Output for Successful EPUB Load

```
📕 Starting EPUB load for book: [Book Title]
📕 Book fileUrl: https://...
📕 Book format: epub
📕 Fetching EPUB from: http://localhost:8000/api/v1/books/[id]/file
📕 Fetch response status: 200
📕 Response OK: true
📕 Blob created, size: [X] bytes, type: application/epub+zip
📕 Data URL created, length: [X] chars
✅ EPUB blob URL set, will send to iframe
📕 Creating EPUB viewer iframe with viewType: epub-viewer-[id]-[timestamp]
📕 EPUB viewer URL: /epubjs/web/custom_epub_viewer.html
📕 View factory called for viewId: [X]
✅ EPUB iframe loaded successfully
📕 Attempting to send EPUB URL (500ms delay)
📨 Sending EPUB URL to iframe (data URI length: [X] chars)
✅ EPUB URL sent successfully via postMessage
```

Then in the iframe console:

```
🎬 EPUB Viewer script started
📍 Current location: http://localhost:3000/epubjs/web/custom_epub_viewer.html
✅ DOM ready, EPUB viewer initialized
📚 EPUB.js library available: true
📦 JSZip library available: true
Received from Flutter: {type: "loadEPUB", url: "data:application/epub+zip;base64,..."}
📖 loadEPUB called with URL type: string
📖 Creating ePub object...
📚 EPUB book object created
⏳ Waiting for book to open...
✅ Book opened AND ready
🎨 Rendition created
🎯 Calling rendition.display()...
✅ EPUB displayed successfully
```

## Next Steps

1. Run the app with: `flutter run -d chrome --web-port 3000`
2. Open browser DevTools (F12) and watch the Console tab
3. Navigate to an EPUB book
4. Share the console output if issues persist

## Files Modified

1. `/pubspec.yaml` - Fixed assets configuration
2. `/lib/ui/widgets/reading/reading_viewer.dart` - Added debugging and error handling
3. `/web/epubjs/web/custom_epub_viewer.html` - Added validation and better error messages
4. `/web/epubjs/test_epub_viewer.html` - Created test page

## Additional Notes

- EPUB files are converted to base64 data URIs before being sent to the viewer
- Large EPUB files (>50MB) may cause performance issues
- The viewer requires internet connection to load EPUB.js from CDN
- All EPUB-related logs use the 📕 emoji for easy filtering
