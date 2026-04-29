# Lost & Found (FULafia) Mobile App

## Overview

**Lost & Found** (also known as **FULafia**) is a cross‑platform Flutter mobile application that helps university students report, discover, and claim lost items on campus.  The app provides a clean, premium UI with pull‑to‑refresh feeds, real‑time notifications, and automatic status updates when a claim is approved.

---

## Key Features

- **Item Feed** – Browse active lost/found listings with a smooth pull‑to‑refresh implementation.
- **Claim Workflow** – Submit a claim, receive approval/rejection notifications, and items automatically transition to *resolved* once approved.
- **Real‑time Notifications**
  - Android: heads‑up banner, sound, vibration, high‑importance channel.
  - iOS: alert, badge, sound via `DarwinNotificationDetails`.
  - Permissions are requested at app start (Android 13+ & iOS).
- **Firebase Firestore backend** – stores items, claims, and per‑user notifications.
- **Responsive UI** – Gradient app bar, glass‑morphism background, modern typography (Google Fonts `Inter`).
- **Extensible architecture** – services (`NotificationService`, `ClaimService`) are isolated for easy unit testing.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter (Dart) – `Material`, `Cupertino`, custom widgets |
| State Management | Provider (simple, lightweight) |
| Backend | Firebase Firestore (real‑time sync) |
| Notifications | `flutter_local_notifications` (Android & iOS) |
| Build System | `flutter pub get` / `flutter run` |

---

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/lost_and_found.git
   cd lost_and_found
   ```
2. **Install Flutter** (≥ 3.22) and the required SDKs – see the official Flutter installation guide.
3. **Configure Firebase**
   - Create a Firebase project and enable Firestore.
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in the respective platform folders (`android/app/` and `ios/Runner/`).
   - Add the Firebase config to `android/app/build.gradle` and `ios/Runner.xcodeproj` as described in the Firebase docs.
4. **Install dependencies**
   ```bash
   flutter pub get
   ```
5. **Run the app**
   ```bash
   flutter run
   ```
   You can target a connected Android device, iOS device, or an emulator.

---

## Usage

- **Home Screen** – Displays two tabs: *Lost* and *Found*. Pull down to refresh the feed.
- **Item Details** – Tap an item to see its description, location, and contact button.
- **Claim an Item** – Press *Claim*, fill your name, and submit. The reporter receives a notification.
- **Approve/Reject** – The reporter can approve a claim in the web console (or via a future admin UI). Approved claims trigger a push notification and automatically update the item status to *resolved*.
- **Notifications** – When the app is backgrounded, users receive a heads‑up banner with sound/vibration. Permissions are requested on first launch.

---

## Architecture Overview

```
lib/
│   main.dart                # App entry point
│   app.dart                 # MaterialApp, theme, routes
│   models/                  # Data models (Item, Claim, Notification)
│   services/                # Business logic (NotificationService, ClaimService)
│   providers/               # State management (AuthProvider, FeedProvider)
│   screens/                 # UI pages (HomeScreen, ItemScreen, ClaimScreen)
│   widgets/                # Re‑usable UI components (DoodleAppBar, ItemCard)
│   utils/                   # Helper functions (date formatting, validators)
└──
```

- **NotificationService** – Handles permission requests, builds the Android channel with `Importance.max` and `Priority.max`, and shows local notifications.
- **ClaimService** – Sends claim data to Firestore, updates item status to `ItemStatus.resolved` after approval.
- **Pull‑to‑Refresh** – Implemented via `RefreshIndicator` wrapped inside each feed widget, ensuring it works even when the list is empty.

---

## Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/awesome‑feature`).
3. Follow the existing code style – use `dartfmt`/`flutter analyze` before committing.
4. Write unit tests for new logic (see `test/` folder).
5. Submit a pull request – reviewers will verify that the app still builds on both Android and iOS.

---

## License

This project is licensed under the **MIT License** – see the `LICENSE` file for details.

---

## Contact / Supervisor

If any changes are required by your supervisor, simply update the relevant files, run `flutter test` to ensure nothing broke, and push to the `master` branch. The app is now production‑ready for field testing.
