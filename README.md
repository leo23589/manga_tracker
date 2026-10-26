# Manga Tracker 📚

A modern, fast, and feature-rich Flutter application to track your manga reading progress, import titles from MangaDex, and automatically sync read chapters via a custom Firefox Mobile extension.

![Manga Tracker Mascot](assets/images/orange_cat.png)

---

## ✨ Features

- **📖 MangaDex API Integration**:
  - Search online titles directly across [MangaDex](https://mangadex.org).
  - Prefers official English titles while supporting multilingual search (Japanese, Romaji, French, Spanish, etc.).
  - 1-tap **"Add to My Library"** or **"Link / Sync with MangaDex"** for existing library items.
  - Automatically downloads cover art images locally to your device.

- **🦊 Firefox Extension Real-Time Sync**:
  - Firefox Mobile & Desktop WebExtension that auto-syncs your read chapters when closing tabs on your favorite reading sites (e.g. MangaDex, Manganato, ReadManga).
  - Automatically filters non-chapter URLs (e.g. `/about`, `/contact`, `/user`).
  - **Quick Add Suggestions**: Displays a floating banner with cover art and a `[ Quick Add ]` button when you read a new manga not yet in your library.
  - Enforces strictly superior chapter updates so older chapter re-reads never overwrite your latest progress.

- **🔔 Native System Notifications**:
  - Sends phone notifications when chapters update or when new manga suggestions are detected.

- **🏷️ Reading Statuses**:
  - Track titles by status: `Reading`, `Finished`, `On Hold`, `Dropped`, or `Plan to Read`.
  - Filter your local library by status with 1-tap filter chips.

- **📦 100% Offline & Embedded Base64 Backup**:
  - All cover art and library data are saved locally on your device disk.
  - Export your entire library into a single `manga_backup.json` file with **embedded Base64 cover images**.
  - Includes an offline fallback screen featuring the custom "no connection" mascot.

- **🎨 Midnight Dark Theme & Cat Mascot**:
  - Deep Midnight OLED dark theme (`#0F0F14`).
  - Custom 2D calico cat mascot and startup splash screen with a percentage progress bar (`0%` ➔ `100%`).

---

## 🛠️ System Architecture

```
 ┌──────────────────────────────────────────────┐
 │  Firefox Mobile / Desktop Extension          │
 │  (Monitors closed tabs on allowed sites)     │
 └──────────────────────┬───────────────────────┘
                        │ HTTP POST (http://127.0.0.1:8080/update)
                        ▼
 ┌──────────────────────────────────────────────┐
 │  Manga Tracker App (Local Background Server) │
 │  - Normalizes title slugs (e.g. one-piece)   │
 │  - Updates local chapter if > current        │
 │  - Prompts "Quick Add" banner if missing      │
 └──────────────────────┬───────────────────────┘
                        │
                        ▼
 ┌──────────────────────────────────────────────┐
 │  MangaDex REST API (https://api.mangadex.org)│
 │  - Fetches English titles, covers, synopses  │
 └──────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / Xcode
- Android device or emulator (Android 5.0+ / SDK 21+)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/leo23589/manga_tracker.git
   cd manga_tracker
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 🦊 Setting Up the Firefox Extension

1. Open Firefox Desktop or Firefox Nightly on your phone.
2. Go to `about:debugging#/runtime/this-firefox` (or connect your phone via USB debugging).
3. Click **Load Temporary Add-on...** and select `extension/manifest.json`.
4. Open extension options to manage your allowed site list (e.g., `mangadex.org`, `manganato.com`).
5. Click **"Test Connection to App"** while the Flutter app is running to verify connection!

---

## 📦 Building for Android

To generate a debug or release APK for your phone:

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

The output file is located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📜 Credits & Acknowledgments

- **MangaDex API**: This application uses the free, open [MangaDex REST API](https://api.mangadex.org) for searching manga, retrieving cover art, synopses, and genre tags. MangaDex is an independent, non-commercial manga platform. All manga titles and cover art remain the property of their respective creators and publishers.
- **Flutter & Dart**: Built with Flutter and Material 3.
- **Provider**: For state management.
- **Flutter Local Notifications**: For native device notifications.
- **Path Provider & Share Plus**: For local storage and JSON backup export/import.
