# Manga Tracker 📚

A modern, fast, and feature-rich Flutter application to track your manga/manhwa reading progress, search & link titles with **MangaDex** and **AniList**, and automatically sync read chapters via a custom Firefox Mobile extension.

![Manga Tracker Mascot](assets/images/orange_cat.png)

---

## ✨ Features

- **📖 MangaDex & 🌸 AniList Multi-Provider API Integration**:
  - Search online titles directly across [MangaDex](https://mangadex.org) and [AniList GraphQL API](https://anilist.co).
  - **Strict English Title Prioritization**: Automatically filters out CJK scripts, Hangul, and Romanized Korean transliterations in favor of official English titles.
  - **Clean Alternative Titles**: Deduplicates `altTitles` while strictly filtering for English, French, and Romaji titles.
  - **1-Tap Title Swapping**: Swap your main title with any alternative title or add custom alt titles directly from the detail view.
  - Distinct provider badges: **`MangaDex 🐱`** (Indigo) and **`AniList 🌸`** (Soft Blue). A single title can hold both links simultaneously!
  - **Multi-Provider Cover Art Grid**: Browse multi-volume cover art grids from both MangaDex and AniList without distracting text.

- **🦊 Firefox Extension Real-Time Sync**:
  - Firefox Mobile & Desktop WebExtension that auto-syncs read chapters when closing tabs on your favorite sites (`mangadex.org`, `manganato.com`, `mgeko.cc`, `manganami.com`, etc.).
  - **Smart Prefix/Suffix Hash Cleaning**: Strips random site code prefixes (e.g. `482q-`, `U23q-`, `K235K-`, `k798lLM-`) and language suffixes (`-eng-li`, `-mcqyg`) while preserving ordinal numbers (`13th`, `3rd`, `100`).
  - **Smart Chapter vs Title Detection**:
    - **Chapter Links** (`/chapter-188`) ➔ Automatically updates chapter progress or prompts to add as **`Reading`**.
    - **Title Info Pages** (`/title/uuid/manga-name`) ➔ Automatically suggests adding as **`Plan to Read`**.
  - **Near Full-Screen Queue Modal**: Stacks all closed tabs into an expandable queue with individual `[Link to Existing]`, `[Skip]`, or `[Add New]` controls.
  - **Auto-Learns Alt Titles**: Linking a detected extension title with an existing library item automatically saves that name as a new `altTitle` for seamless future auto-matching.

- **🔔 System Notifications & 30-Day Activity Logs**:
  - Sends phone notifications when chapters update, when new suggestions are detected, when library titles are already up to date, or when the Firefox extension connects/disconnects!
  - **Heartbeat Connection Tracker**: Periodically tracks extension sync status and alerts on connection or disconnection.
  - **Activity Log Drawer 🔔**: Tap the bell icon on the Home Page to view recent sync logs with relative timestamps (*"5m ago"*, *"Yesterday"*). Logs are **automatically purged after 30 days**.

- **🔍 Home Page Quick Search & Custom Filters**:
  - Search library titles and alternative titles directly from the Home Page search bar.
  - Filter chips for status (`Reading`, `Finished`, `Plan to Read`, `On Hold`, `Dropped`) and link status (`Linked 🔗` / `Not Linked 📍`).
  - **Vibrant Manhwa Tag**: Styled with a distinct **Amber/Orange badge 🟧** (`#D97706`).
  - **Format Exclusivity**: Enforces mutual exclusivity between `Manga` and `Manhwa` content tags.

- **⚡ Performance & Memory Optimizations**:
  - `IndexedStack` + `AutomaticKeepAliveClientMixin` for instant 0ms tab switching without re-building widgets or losing scroll state.
  - Retina 2x image memory cache downsampling (`cacheWidth`/`cacheHeight`) to prevent memory leaks and crashes.
  - Smooth animated splash screen with percentage progress indicator (`0%` ➔ `100%`).

- **📦 100% Offline & Embedded Base64 Backup**:
  - All cover art and library data are saved locally on your device disk.
  - Export your entire library into a single `manga_backup.json` file with **embedded Base64 cover images**.
  - Includes an offline fallback screen featuring the custom "no connection" mascot.

- **🎨 Midnight Dark Theme & Cat Mascot**:
  - Deep Midnight OLED dark theme (`#0F0F14`).
  - Custom 2D calico cat mascot and startup splash screen.
  - High-resolution native Android launcher icon centered with padding so no paws or tails are clipped.

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
 │  - Normalizes title slugs & cleans hashes    │
 │  - Matches local titles, altTitles & URLs    │
 │  - Prompts Near Full-Screen Queue Modal      │
 └──────────────┬────────────────────────┬──────┘
                │                        │
                ▼                        ▼
 ┌────────────────────────┐  ┌────────────────────────┐
 │  MangaDex REST API     │  │  AniList GraphQL API   │
 │  (https://mangadex.org)│  │  (https://anilist.co)  │
 └────────────────────────┘  └────────────────────────┘
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

## 🦊 Installing the Firefox Extension Permanently

1. **Option A (Firefox Mobile / Desktop via AMO Self-Signing)**:
   * Upload `manga_tracker_extension.xpi` to [addons.mozilla.org/developers/addon/submit/upload-unlisted](https://addons.mozilla.org/en-US/developers/addon/submit/upload-unlisted).
   * Mozilla signs it in ~1 min. Tap the resulting download link in Firefox on your phone to install **permanently**!

2. **Option B (Temporary Loading)**:
   * Open Firefox ➔ `about:debugging` ➔ **Load Temporary Add-on...** ➔ Select `extension/manifest.json`.

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

- **MangaDex API**: Uses the free, open [MangaDex REST API](https://api.mangadex.org) for searching titles, cover arts, and tags.
- **AniList API**: Uses the free [AniList GraphQL API](https://graphql.anilist.co) for anime and manga database integration.
- **Flutter & Dart**: Built with Flutter and Material 3.
- **Provider**: For state management.
- **Flutter Local Notifications**: For native device notifications.
