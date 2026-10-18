# Live Detect

Real-time object detection on Android and iOS. The camera feed stays on the phone. A YOLO nano model labels everyday objects (person, phone, bottle, car, and about 80 COCO classes).

First launch needs internet so the official model can download and cache. After that it works offline.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.32 or newer
- A **physical phone** (emulators are a poor camera/GPU test)
- Android Studio + a device or USB debugging for Android
- Xcode on a Mac for iOS

If Flutter is not on your PATH, the SDK can live at `C:\src\flutter` and you can call `C:\src\flutter\bin\flutter`.

## Run on your phone

```bash
cd RealTime-Object-Detection-using-Mobile
flutter pub get
flutter run
```

Allow camera access, wait for the model download, then point the camera at objects.

## Share with friends

### Android (easiest)

Build a release APK and send the file (WhatsApp, Drive, email):

```bash
flutter build apk --release
```

The installable file is:

`build/app/outputs/flutter-apk/app-release.apk`

Friends must enable install from unknown sources (or “install this app anyway”) the first time.

Google Play **internal testing** is optional if you later want a store link.

### iPhone

Apple does not let you casually email an IPA. Friends need **TestFlight**, which requires a paid [Apple Developer](https://developer.apple.com) account.

On a Mac:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Set your signing team
3. Archive and upload to App Store Connect
4. Add testers in TestFlight and share the invite

Without that account, only Android friends can install a build you send.

## Project layout

- `lib/main.dart` — app theme
- `lib/screens/permission_gate.dart` — camera permission
- `lib/screens/detect_screen.dart` — live `YOLOView`, confidence, flip camera, torch

Detection uses the official [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) plugin and the `yolo26n` model.

## License note

Ultralytics YOLO is AGPL-3.0 for this open-source setup. Commercial closed-source use may need an Ultralytics enterprise license.
