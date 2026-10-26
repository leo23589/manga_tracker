# 📚 Manga Tracker Firefox Extension

This extension automatically updates your read chapters in the **Manga Tracker** Flutter app whenever you close a tab on allowed manga sites.

## 🚀 How It Works

1. The extension monitors tab close events on sites you specify in options (e.g. `mangadex.org`, `manganato.com`).
2. It parses the URL to extract the title slug (e.g., `one-piece`) and chapter number (e.g., `1081`).
3. It sends a local HTTP POST request to your running Manga Tracker Flutter app at `http://127.0.0.1:8080/update`.
4. **App Behavior**:
   - If the manga exists in your library, the app automatically updates the chapter count.
   - If the manga is NOT in your library, a banner appears in the app asking if you want to **"Quick Add"** it to your library (which automatically fetches cover art and synopsis from MangaDex!).

## 📱 How to Install on Firefox (Mobile / Desktop)

### On Firefox Desktop / Android Nightly:
1. Open Firefox and go to `about:debugging#/runtime/this-firefox`.
2. Click **"Load Temporary Add-on..."**.
3. Select the `manifest.json` file inside this `extension/` folder.
4. Click the extension icon or open `about:addons` options to manage your list of tracked manga websites.

### Test Connection
Click **"Test Connection to App"** in the extension options page while the Manga Tracker Flutter app is running on your phone/emulator!
