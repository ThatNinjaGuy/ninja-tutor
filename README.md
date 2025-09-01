# ninja_tutor

## Running the Application

### Running on Web

To run the Flutter application as a web server for web testing, use the following command:

```bash
flutter run -d web-server --web-port 3000
```

After running the command, open `http://localhost:3000` in your web browser (e.g., Microsoft Edge) to access the application.

### Running on iOS

To run the Flutter application on an iOS simulator or device:

1. First, check available iOS devices:

```bash
flutter devices
```

2. Run the app on a specific iOS simulator using its device ID:

```bash
flutter run -d [DEVICE_ID]
```

For example:

```bash
flutter run -d 582084D3-7640-47AA-B83C-D56F168DDACE
```

### Running on Chrome

To run the Flutter application directly in Chrome:

```bash
flutter run -d chrome --web-port 3000
```
