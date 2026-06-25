# LocShare

A Flutter app for sharing your live location with friends and family **only after they approve**. Built for iOS and Android with Google Maps and Firebase.

## Features

- **Account sign-up / sign-in** with email and password
- **Approval-based sharing** — send a request by email; tracking starts only after approval
- **Mutual tracking** — once approved, both people can see each other on the map
- **Google Maps** — view your location and approved contacts in real time
- **Share toggle** — turn location sharing on or off at any time

## Architecture

```
lib/
├── main.dart                 # App entry + Firebase init
├── app.dart                  # Material app shell
├── models/                   # User, location, connection models
├── services/                 # Auth, location, sharing services
├── providers/app_state.dart  # App-wide state (Provider)
└── screens/                  # Login, map, connections UI
```

**Backend:** Firebase Authentication + Cloud Firestore

| Collection     | Purpose                                      |
|----------------|----------------------------------------------|
| `users`        | Profile (name, email, sharing preference)    |
| `locations`    | Latest coordinates per user                  |
| `connections`  | Sharing requests (`pending` / `approved`)    |

## Prerequisites

1. [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. A [Firebase project](https://console.firebase.google.com/)
3. A [Google Maps API key](https://developers.google.com/maps/documentation/maps-sdk/get-api-key) with:
    - **Maps SDK for Android**
    - **Maps SDK for iOS**

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

Install the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

From the project root:

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.

Enable in the Firebase Console:

- **Authentication** → Email/Password
- **Cloud Firestore** → Create database

Deploy security rules:

```bash
firebase deploy --only firestore:rules
```

(Or paste `firestore.rules` into the Firebase Console → Firestore → Rules.)

Create a composite index if prompted when running the app (Firestore will log a link).

### 3. Add Google Maps API keys

**Android** — edit `android/app/src/main/res/values/strings.xml`:

```xml
<string name="google_maps_api_key">YOUR_ANDROID_MAPS_KEY</string>
```

**iOS** — edit `ios/Runner/Info.plist`:

```xml
<key>GMSApiKey</key>
<string>YOUR_IOS_MAPS_KEY</string>
```

Restrict keys in Google Cloud Console to your app’s bundle ID / SHA-1.

### 4. Run the app

```bash
# iOS simulator or device
flutter run -d ios

# Android emulator or device
flutter run -d android
```

## How to use

1. **Create accounts** for yourself and a family member (each on their own device).
2. On the **Family** tab, enter the other person’s email and tap **Send**.
3. The recipient opens **Family → Pending approvals** and taps **Approve**.
4. Both users turn on the **Share** toggle in the app bar.
5. Open the **Map** tab to see live locations.

## Permissions

- **Location (when in use)** — required to share and display your position on the map.

## Project structure notes

- Location updates are pushed to Firestore when sharing is enabled (every ~25 m movement).
- Approved contacts subscribe to each other’s `locations/{userId}` documents in real time.
- Connection document IDs are deterministic (`userA_userB`) so Firestore rules can enforce access.

## Next steps (optional enhancements)

- Push notifications for incoming sharing requests
- Background location updates on iOS/Android
- Profile photos and contact nicknames
- Geofencing / arrival alerts

## License

Private project — not published to pub.dev.
