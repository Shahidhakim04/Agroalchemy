# Switch to a New Firebase Account / Project

Follow these steps to use a different Firebase account (and project) with AgroAlchemy.

---

## 1. New Firebase project (new account)

1. Go to [Firebase Console](https://console.firebase.google.com/).
2. **Sign in** with the Google account you want to use.
3. Click **Add project** (or **Create a project**).
4. Enter a **project name** (e.g. `agroalchemy`).
5. Turn **Google Analytics** on or off as you prefer → **Create project**.
6. When it’s ready, click **Continue** to open the project.

---

## 2. Register your apps in the new project

### Android

1. In the project overview, click the **Android** icon.
2. **Android package name:** use the same as your app:  
   `com.hackathonApp`  
   (from `android/app/build.gradle.kts` → `applicationId`).
3. (Optional) App nickname and SHA-1 if you use Google Sign-In with release builds.
4. Click **Register app**.
5. **Download `google-services.json`**.
6. Place it in your Flutter app:
   - Replace: `agro_alchemy_ui/android/app/google-services.json`
   - Replace: `agro_alchemy_ui/android/app/src/main/google-services.json`  
   (or use one path and a copy/symlink so both exist if your build expects both.)

### iOS (if you build for iOS)

1. In the project overview, click the **iOS** icon.
2. **iOS bundle ID:** use the same as your app:  
   `com.example.agroAlchemyUi`  
   (from `lib/firebase_options.dart` or Xcode).
3. (Optional) App nickname.
4. Click **Register app**.
5. **Download `GoogleService-Info.plist`**.
6. Add it to Xcode: open `ios/Runner.xcworkspace` in Xcode, drag `GoogleService-Info.plist` into the **Runner** target (e.g. under Runner in the Project Navigator).

### Web (if you use Flutter web)

1. In the project overview, click the **Web** icon (`</>`).
2. **App nickname** (optional).
3. Click **Register app**.
4. You’ll see a `firebaseConfig` object — you’ll use this in **Step 4** to update `web/index.html`.

---

## 3. Enable Firebase products

In the left sidebar of the Firebase Console:

- **Authentication** → **Get started** → enable **Email/Password**, **Anonymous**, **Google**, **Apple** (as you use in the app).
- **Firestore Database** → **Create database** → choose **production** or **test** mode and location.
- (Optional) **Cloud Messaging** if you use FCM later.

---

## 4. Configure Flutter with FlutterFire CLI (recommended)

This updates `lib/firebase_options.dart` and `firebase.json` for the **new** project.

1. Install FlutterFire CLI (if not already):
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. From your app root (where `pubspec.yaml` is):
   ```bash
   cd agro_alchemy_ui
   flutterfire configure
   ```
3. **Sign in** with the **new** Firebase/Google account when prompted.
4. Select the **new** Firebase project (the one you created in Step 1).
5. Select the platforms you use (e.g. **Android**, **iOS**, **Web**).
6. FlutterFire will:
   - Generate/overwrite `lib/firebase_options.dart` with the new project’s config.
   - Update `firebase.json` with the new project/app IDs.
   - Use the existing `google-services.json` if it’s already in place, or prompt you; ensure it’s the one from the **new** project (from Step 2).

After this, **Dart/Android/iOS** config is tied to the new Firebase project. You only need to update the web config manually (next step).

---

## 5. Update web config (if you use Flutter web)

Edit **`agro_alchemy_ui/web/index.html`** and replace the Firebase script block with the config from your **new** project.

1. In Firebase Console → Project settings → **Your apps** → select the **Web** app → copy the `firebaseConfig` object.
2. In `web/index.html`, find:
   ```html
   <meta name="google-signin-client_id" content="...">
   ```
   Set this to the **Web client ID** from the new project (e.g. from Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration).
3. Replace the existing `firebaseConfig` and init:
   ```html
   var firebaseConfig = {
     apiKey: "NEW_API_KEY",
     authDomain: "NEW_PROJECT_ID.firebaseapp.com",
     projectId: "NEW_PROJECT_ID",
     storageBucket: "NEW_PROJECT_ID.firebasestorage.app",
     messagingSenderId: "NEW_SENDER_ID",
     appId: "NEW_WEB_APP_ID",
     measurementId: "G-XXXX"   // if you use Analytics
   };
   firebase.initializeApp(firebaseConfig);
   firebase.analytics();  // optional
   ```

Use the values from the **new** Firebase project only.

---

## 6. Replace Android `google-services.json` (if not using FlutterFire for it)

If you didn’t use `flutterfire configure` to overwrite the file:

- Download `google-services.json` from the **new** project (Step 2 – Android).
- Replace:
  - `agro_alchemy_ui/android/app/google-services.json`
  - `agro_alchemy_ui/android/app/src/main/google-services.json`  
  with this new file.

---

## 7. Clean and run

```bash
cd agro_alchemy_ui
flutter clean
flutter pub get
flutter run
```

Test **sign-in** (Anonymous / Google / Apple) and **Firestore** (e.g. profile, crop history) against the new project.

---

## Checklist

- [ ] New Firebase project created with the new account.
- [ ] Android app registered; `google-services.json` replaced in `android/app/` (and `android/app/src/main/` if used).
- [ ] iOS app registered (if needed); `GoogleService-Info.plist` added in Xcode.
- [ ] Web app registered (if needed); `web/index.html` updated with new `firebaseConfig` and Google client ID.
- [ ] Authentication and Firestore enabled in the new project.
- [ ] `flutterfire configure` run and new project selected (so `lib/firebase_options.dart` and `firebase.json` are for the new project).
- [ ] `flutter clean` and `flutter pub get` run; app tested on device/emulator.

---

## Files that will change

| File | What changes |
|------|------------------|
| `lib/firebase_options.dart` | New API keys, project ID, app IDs (via `flutterfire configure`). |
| `firebase.json` | New project ID and app IDs (via `flutterfire configure`). |
| `android/app/google-services.json` | Replaced by file from new project. |
| `android/app/src/main/google-services.json` | Same as above (keep in sync). |
| `ios/Runner/GoogleService-Info.plist` | Added from new project (if you use iOS). |
| `web/index.html` | New `firebaseConfig` and Google Sign-In client ID. |

After this, the app uses only the new Firebase account/project.
