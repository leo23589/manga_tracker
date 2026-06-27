# Liste de Manga 📚

A modern, clean, and feature-rich Manga tracking application built with Flutter. Keep track of your reading progress, rate your favorite titles, and visualize your reading statistics.

## ✨ Features

- **Progress Tracking**: Easily update the current chapter of the manga you are reading.
- **Detailed Library**: Store titles, synopses, ratings, and custom covers.
- **Advanced Search**: Filter your collection by title, minimum rating, or specific genres/themes.
- **Smart Sorting**: Organize your list by recently added, recently updated, alphabetical order, or rating.
- **Statistics Dashboard**: Visualize your reading habits with charts and data on your favorite genres.
- **Local Persistence**: Your data is automatically saved on your device and remains available offline.
- **Backup & Restore**: Export your entire collection as a JSON file to transfer it to another device or keep it safe.
- **Custom UI**: Beautiful dark mode theme with a focus on usability.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version recommended)
- Android Studio / VS Code
- Android/iOS emulator or physical device

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/manga_tracker.git
   ```
2. Navigate to the project folder:
   ```bash
   cd manga_tracker
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 📦 Building the APK

To generate a production-ready APK for your Android device:

```bash
flutter build apk --release
```

The resulting file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## 💾 Backup System

To move your data to a new phone:
1. Go to the **Statistics** tab.
2. Tap **Exporter** to save your backup file.
3. On the new device, open the app, go to Statistics, and tap **Importer** to select your backup file.

## 🛠 Technologies Used

- **Flutter & Dart**
- **Provider**: For state management.
- **Path Provider**: For local file system access.
- **Share Plus**: For backup sharing.
- **File Picker**: For backup restoration.
- **Image Picker**: For custom manga covers.
