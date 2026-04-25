# AgroAlchemy – Mobile App

AgroAlchemy is a **Flutter mobile application** for farmers: crop insights, fertilizer suggestions, yield estimates, disease detection, and in-app assistance.

---

## Features

- **Firebase Auth** – Login and signup
- **Fertilizer recommender** – Suggestions based on soil and crop (uses API when backend is available)
- **Yield & pesticide estimator** – Estimates from state, season, rainfall, area
- **Plant disease detector** – Image-based disease detection (uses API when backend is available)
- **Pesticide recommender** – Recommendations from detected disease
- **Crop history & calendar** – Past predictions and planning
- **Chatbot** – In-app assistant
- **Multi-language** – English, Hindi, Marathi (via `l10n`)

---

## Tech stack

| Layer   | Stack                    |
|--------|---------------------------|
| App    | **Flutter** (Android, iOS) |
| Auth   | **Firebase Authentication** |
| Data   | **Firebase Firestore**    |

---

## Setup and run

The app lives in the `agro_alchemy_ui` folder.

```bash
cd agro_alchemy_ui
flutter pub get
flutter run
```

### Optional: API / backend

Some features (fertilizer, yield, disease) call an API. Configure the base URL in `agro_alchemy_ui`:

- Create `.env` in `agro_alchemy_ui` with `API_BASE_URL=<your-backend-url>`  
- Or the app falls back to the default in `lib/config.dart`.

Without a backend, those API-dependent features will not work until you point `API_BASE_URL` to a running server.

---

## Project structure

```
AgroAlchemy/
├── README.md           (this file)
└── agro_alchemy_ui/    ← Flutter mobile app
    ├── android/
    ├── ios/
    ├── lib/
    ├── pubspec.yaml
    └── ...
```
