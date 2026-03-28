# 📱 CineVault — Complete APK Build Guide
## From Zero to APK (Termux + GitHub Actions)

---

## ⚡ METHOD 1: GitHub Actions (EASIEST — Recommended)
> Build APK in the cloud. No PC needed. Works 100% from Termux.

### STEP 1 — Get a FREE TMDB API Key
1. Go to **https://www.themoviedb.org/**
2. Create a free account
3. Go to Settings → API → Request an API Key → Developer
4. Copy your **API Key (v3 auth)**
5. Open `lib/services/tmdb_service.dart`
6. Replace `YOUR_TMDB_API_KEY` with your actual key

---

### STEP 2 — Push code to GitHub from Termux

```bash
# In Termux, install git if not installed
pkg install git -y

# Navigate to your cinevault folder
cd ~/cinevault

# Initialize git repo
git init
git add .
git commit -m "Initial CineVault commit"

# Create repo on GitHub at: https://github.com/new
# Name it: cinevault (private or public, your choice)

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/cinevault.git
git branch -M main
git push -u origin main
```

When it asks for password → use a GitHub **Personal Access Token** (not your GitHub password):
- GitHub.com → Settings → Developer Settings → Personal Access Tokens → Generate New (Classic)
- Check: `repo` scope → Generate → copy the token → paste as password

---

### STEP 3 — GitHub Actions builds your APK automatically

After push, go to:
**https://github.com/YOUR_USERNAME/cinevault/actions**

You will see the workflow **"Build CineVault APK"** running automatically.
Wait 8–15 minutes → it builds the APK in the cloud.

**Download your APK:**
- Click the workflow run
- Scroll down to **Artifacts**
- Download **CineVault-APK**
- Unzip → install `app-arm64-v8a-release.apk` on your phone

---

### STEP 4 — Install APK on Android

1. Transfer APK to your phone (or download directly from GitHub)
2. Go to **Settings → Security → Unknown Sources** → Enable
   - (Android 8+): Settings → Apps → Special App Access → Install Unknown Apps → Your browser → Allow
3. Open the APK file → Install
4. Open **CineVault** → Done! ✅

---

## 🔧 METHOD 2: Build Locally in Termux (Advanced)

### Prerequisites — Install everything in Termux

```bash
# Step 1: Update Termux
pkg update && pkg upgrade -y

# Step 2: Install required packages
pkg install git curl wget unzip openjdk-17 -y

# Step 3: Install Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Step 4: Accept Flutter
flutter doctor --android-licenses
flutter doctor

# Step 5: Set JAVA_HOME
echo 'export JAVA_HOME=/data/data/com.termux/files/usr' >> ~/.bashrc
source ~/.bashrc
```

---

### Build the APK

```bash
# Go to project folder
cd ~/cinevault

# Get all dependencies
flutter pub get

# Generate Hive adapters (IMPORTANT — do this before building)
flutter pub run build_runner build --delete-conflicting-outputs

# Build Release APK (smaller, optimized)
flutter build apk --release

# OR build split APKs (smaller file size)
flutter build apk --release --split-per-abi

# Your APK is at:
# build/app/outputs/flutter-apk/app-release.apk          ← Universal
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ← Modern phones
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← Older phones
```

---

## 🔄 METHOD 3: Update APK (Push Changes)

Whenever you change code:

```bash
cd ~/cinevault

# Make your changes to any file...

# Stage and commit
git add .
git commit -m "Update: added new feature"

# Push → GitHub Actions auto-builds new APK
git push origin main
```

Go to GitHub Actions → wait → download new APK.

---

## 📦 COMPLETE FILE STRUCTURE

```
cinevault/
├── lib/
│   ├── main.dart                          ← App entry, 5-tab nav
│   ├── theme/
│   │   └── app_theme.dart                 ← AMOLED black theme
│   ├── models/
│   │   ├── movie_model.dart               ← Movie, StreamSource, Cast models
│   │   └── movie_model.g.dart             ← Hive adapters (auto-generated)
│   ├── services/
│   │   ├── tmdb_service.dart              ← TMDB API: trending, search, details
│   │   ├── storage_service.dart           ← Watchlist, history, settings (Hive)
│   │   └── download_service.dart          ← Download manager (pause/resume/delete)
│   ├── providers/
│   │   └── stream_providers.dart          ← Provider system (VidSrc, FlixHQ, etc.)
│   ├── screens/
│   │   ├── home_screen.dart               ← Home: banner, OTT filter, rows
│   │   ├── search_screen.dart             ← Live search with filters
│   │   ├── movie_detail_screen.dart       ← Detail: cast, trailer, watch/download
│   │   ├── player_screen.dart             ← Video player + 1-click download
│   │   ├── watchlist_screen.dart          ← Continue watching + history
│   │   ├── downloads_screen.dart          ← Download manager UI
│   │   └── settings_screen.dart          ← Settings + Admin panel
│   └── widgets/
│       ├── movie_card.dart                ← Reusable movie card
│       └── section_header.dart           ← Section titles + shimmer loader
├── android/
│   ├── app/
│   │   ├── build.gradle                   ← App build config
│   │   ├── proguard-rules.pro             ← Release minification rules
│   │   └── src/main/
│   │       ├── AndroidManifest.xml        ← Permissions
│   │       ├── kotlin/.../MainActivity.kt ← Flutter activity
│   │       └── res/
│   │           ├── xml/network_security_config.xml
│   │           ├── drawable/launch_background.xml
│   │           └── values/styles.xml
│   ├── build.gradle                       ← Root build file
│   ├── settings.gradle                    ← Project settings
│   ├── gradle.properties                  ← Gradle config
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties      ← Gradle version
├── .github/
│   └── workflows/
│       └── build.yml                      ← Auto-build APK on push
└── pubspec.yaml                           ← All dependencies
```

---

## 🎯 WHAT EACH FEATURE DOES

| Feature | How it works | Where in code |
|---------|-------------|---------------|
| Browse movies | TMDB API metadata | `tmdb_service.dart` |
| OTT filter | TMDB watch providers | `home_screen.dart` |
| Live search | Debounced TMDB multi-search | `search_screen.dart` |
| Stream sources | Parallel provider scraping | `stream_providers.dart` |
| Video player | BetterPlayer (HLS + MP4) | `player_screen.dart` |
| 1-click download | Dio background download | `download_service.dart` |
| Pause/Resume download | CancelToken + resume | `download_service.dart` |
| Offline playback | Local file via BetterPlayer | `player_screen.dart` |
| Watch progress sync | Hive local storage | `storage_service.dart` |
| Continue watching | Progress % from Hive | `watchlist_screen.dart` |
| Admin panel | PIN unlock (default: 7749) | `settings_screen.dart` |
| Provider health | Ping test per provider | `settings_screen.dart` |

---

## 🔑 IMPORTANT CONFIGURATIONS

### 1. Set Your TMDB API Key
File: `lib/services/tmdb_service.dart`
```dart
static const String _apiKey = 'YOUR_TMDB_API_KEY'; // ← Replace this
```
Get free key: **https://www.themoviedb.org/settings/api**

### 2. Change Admin PIN
File: `lib/services/storage_service.dart`
```dart
const adminPin = '7749'; // ← Change to your PIN
```

### 3. Change App Package Name
File: `android/app/build.gradle`
```gradle
applicationId "com.cinevault.app"  // ← Change to your domain
```
File: `android/app/src/main/AndroidManifest.xml` + `MainActivity.kt`
```
com.cinevault.app  // ← Change everywhere
```

---

## ❓ COMMON ISSUES

**Problem: `flutter: command not found`**
```bash
source ~/.bashrc
# or
export PATH="$HOME/flutter/bin:$PATH"
```

**Problem: Java not found**
```bash
pkg install openjdk-17 -y
```

**Problem: Hive adapters not found**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Problem: GitHub Actions fails**
- Check your `pubspec.yaml` has no typos
- Check Actions tab for error logs
- Make sure `build.yml` is in `.github/workflows/`

**Problem: APK installs but no movies show**
- You forgot to set your TMDB API key
- Edit `tmdb_service.dart` → add your key → rebuild

**Problem: Videos don't play**
- Providers are scraped sites — they go up/down
- Try a different source in the source picker
- This is normal for aggregator apps

---

## 🚀 DISTRIBUTE YOUR APK

**Option 1 — GitHub Releases (auto via Actions)**
GitHub Actions creates releases automatically with each push.
Share link: `https://github.com/YOUR_USERNAME/cinevault/releases`

**Option 2 — Google Drive / Telegram**
Upload APK to Drive and share link.

**Option 3 — Direct link**
Use GitHub raw APK link from Actions artifacts.

---

## 📞 GETTING A TMDB API KEY (STEP BY STEP)

1. Go to: **https://www.themoviedb.org/**
2. Click **Join TMDB** → Create free account
3. Verify your email
4. Go to: **https://www.themoviedb.org/settings/api**
5. Click **Create** → Choose **Developer**
6. Fill: App Name=CineVault, App URL=https://github.com/you/cinevault, Summary="Personal movie app"
7. Accept terms → Submit
8. Copy the **API Key (v3 auth)** — looks like: `a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4`
9. Paste it in `lib/services/tmdb_service.dart`

---

*CineVault — Built with Flutter. No Firebase. No server. Pure APK.*
