# MajaCraft Mobile - Local Development Guide

## 🚀 Setup untuk Build & Test Lokal (Flutter)

Dokumentasi lengkap untuk build dan test aplikasi Flutter di komputer lokal menggunakan Android emulator.

---

## 📋 Prerequisites

### 1. Install Flutter SDK
- **Version:** Flutter 3.32.6 (stable) atau higher
- **Dart SDK:** 3.8.1 (included with Flutter)
- Download: https://flutter.dev/docs/get-started/install
- Verify: `flutter --version` dan `dart --version`

**Installation:**
```bash
# Windows: Extract to C:\src\flutter
# macOS: Extract to ~/flutter
# Linux: Extract to ~/flutter

# Add to PATH
# Windows: C:\src\flutter\bin
# macOS/Linux: export PATH="$PATH:$HOME/flutter/bin"

# Check installation
flutter doctor
```

### 2. Install Android Studio
- Download: https://developer.android.com/studio
- Install dengan semua default components
- Buka Android Studio → Tools → SDK Manager
- Install:
  - ✅ Android SDK Platform 33 (Android 13)
  - ✅ Android SDK Platform 34 (Android 14)
  - ✅ Android SDK Build-Tools
  - ✅ Android Emulator
  - ✅ Android SDK Platform-Tools
  - ✅ Android SDK Command-line Tools

### 3. Install Flutter & Dart Plugins
1. Open Android Studio
2. Go to **File → Settings → Plugins**
3. Search and install:
   - ✅ **Flutter** plugin
   - ✅ **Dart** plugin (auto-installed with Flutter)
4. Restart Android Studio

### 4. Setup Environment Variables

**Windows:**
```bash
# User Variables
ANDROID_HOME = C:\Users\<YourUsername>\AppData\Local\Android\Sdk

# Path (tambahkan):
C:\src\flutter\bin
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\emulator
%ANDROID_HOME%\cmdline-tools\latest\bin
```

**macOS/Linux:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
export PATH=$PATH:$HOME/flutter/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

### 5. Accept Android Licenses
```bash
flutter doctor --android-licenses
# Type 'y' for all prompts
```

# MajaCraft Mobile - Local Development Guide

## 🚀 Setup untuk Build & Test Lokal (Flutter)

Dokumentasi lengkap untuk build dan test aplikasi Flutter di komputer lokal menggunakan Android emulator.

---

## 📋 Prerequisites

### 1. Install Flutter SDK
- **Version:** Flutter 3.32.6 (stable) atau higher
- **Dart SDK:** 3.8.1 (included with Flutter)
- Download: https://flutter.dev/docs/get-started/install
- Verify: `flutter --version` dan `dart --version`

**Installation:**
```bash
# Windows: Extract to C:\src\flutter
# macOS: Extract to ~/flutter
# Linux: Extract to ~/flutter

# Add to PATH
# Windows: C:\src\flutter\bin
# macOS/Linux: export PATH="$PATH:$HOME/flutter/bin"

# Check installation
flutter doctor
```

### 2. Install Android Studio
- Download: https://developer.android.com/studio
- Install dengan semua default components
- Buka Android Studio → Tools → SDK Manager
- Install:
  - ✅ Android SDK Platform 33 (Android 13)
  - ✅ Android SDK Platform 34 (Android 14)
  - ✅ Android SDK Build-Tools
  - ✅ Android Emulator
  - ✅ Android SDK Platform-Tools
  - ✅ Android SDK Command-line Tools

### 3. Install Flutter & Dart Plugins
1. Open Android Studio
2. Go to **File → Settings → Plugins** (Windows/Linux) or **Android Studio → Preferences → Plugins** (macOS)
3. Search and install:
   - ✅ **Flutter** plugin
   - ✅ **Dart** plugin (auto-installed with Flutter)
4. Restart Android Studio

### 4. Setup Environment Variables

**Windows:**
```bash
# User Variables
ANDROID_HOME = C:\Users\<YourUsername>\AppData\Local\Android\Sdk

# Path (tambahkan):
C:\src\flutter\bin
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\emulator
%ANDROID_HOME%\cmdline-tools\latest\bin
```

**macOS/Linux:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
export PATH=$PATH:$HOME/flutter/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

Restart terminal setelah setup!

### 5. Accept Android Licenses
```bash
flutter doctor --android-licenses
# Type 'y' for all prompts
```

### 6. Verify Installation
```bash
flutter doctor -v
```

Pastikan semua checks ✅ atau minimal Android toolchain dan IDE sudah OK.

---

## 🔧 Setup Project

### 1. Clone Repository
```bash
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Installation
```bash
flutter doctor
flutter analyze
```

---

## 📱 Create Android Emulator

### Via Android Studio (Recommended):
1. Buka Android Studio
2. Tools → Device Manager (atau AVD Manager)
3. Click **"Create Device"**
4. Pilih phone: **Pixel 5** atau **Pixel 6** → Next
5. Pilih system image: **Android 13 (API 33)** atau **Android 14 (API 34)**
6. Click "Download" jika belum ada → Next
7. Verify Configuration → Finish
8. Launch emulator dengan tombol ▶️

### Via Command Line:
```bash
# List available emulators
flutter emulators

# atau
emulator -list-avds

# Start emulator
flutter emulators --launch <emulator_id>

# atau
emulator -avd Pixel_5_API_33
```

---

## 🎯 Run App di Emulator

### Method 1: Flutter Run (Recommended)

**Step 1 - Check Devices:**
```bash
flutter devices
```

**Step 2 - Run App:**
```bash
flutter run

# Or specify device
flutter run -d <device-id>

# Hot reload mode (default)
# Press 'r' untuk hot reload
# Press 'R' untuk hot restart
# Press 'q' untuk quit
```

### Method 2: Via Android Studio/VS Code

**Android Studio:**
1. Open project di Android Studio
2. Wait for indexing & Gradle sync
3. Select device di dropdown (top toolbar)
4. Click ▶️ Run button (atau Shift+F10)

**VS Code:**
1. Open project di VS Code
2. Install Flutter extension
3. Press F5 atau Run → Start Debugging
4. Select device dari command palette

---

## 🔍 Debugging

### View Logs:
```bash
# Flutter logs (during flutter run)
# Logs otomatis muncul di terminal

# Android Logcat (detailed):
adb logcat | grep -i "flutter"

# atau via Android Studio:
# View → Tool Windows → Logcat
```

### Flutter DevTools:
```bash
# Start DevTools
flutter pub global activate devtools
flutter pub global run devtools

# atau run app dengan DevTools
flutter run --observatory-port=9200
# Lalu buka URL yang muncul di browser
```

### Hot Reload:
- **Hot Reload (r):** Update UI tanpa restart app
- **Hot Restart (R):** Restart app dengan state reset
- **Full Restart:** Stop dan run ulang

### Common Issues:

#### 1. Gradle Build Failed
```bash
# Clean build
flutter clean
flutter pub get

# atau manual clean Gradle
cd android
./gradlew clean
cd ..
flutter run
```

#### 2. Emulator Not Detected
```bash
adb devices         # Cek device terhubung
adb kill-server     # Kill ADB
adb start-server    # Start ulang
flutter devices     # Re-check
```

#### 3. Pub Get Error
```bash
# Clear pub cache
flutter pub cache clean
flutter pub get
```

#### 4. "Waiting for another flutter command to release the startup lock"
```bash
# Delete lock file
# Windows: del %USERPROFILE%\.flutter\pub-cache\pubspec.lock
# macOS/Linux: rm ~/.flutter/pub-cache/pubspec.lock

# Atau kill Flutter process
taskkill /F /IM dart.exe  # Windows
killall dart              # macOS/Linux
```

---

## 📦 Build Production APK

### Build Release APK:
```bash
# Build standard APK
flutter build apk --release

# Output:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build Split APKs (Smaller Size):
```bash
# Build APK per ABI (armeabi-v7a, arm64-v8a, x86_64)
flutter build apk --split-per-abi

# Outputs 3 APKs:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Build App Bundle (Recommended for Play Store):
```bash
# Build Android App Bundle
flutter build appbundle --release

# Output:
# build/app/outputs/bundle/release/app-release.aab
```

### Install APK to Device:
```bash
# Install ke emulator/device yang terhubung
flutter install

# atau manual via adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Note:** Release build requires proper signing configuration in `android/app/build.gradle`. Untuk development testing, gunakan debug build atau configure signing key.

---

## 🏗️ Project Structure

```
majacraft-mobile/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── config/
│   │   └── api_config.dart               # API base URL configuration
│   ├── providers/
│   │   └── auth_provider.dart            # Authentication state management
│   ├── services/
│   │   ├── api_service.dart              # HTTP client wrapper
│   │   ├── auth_service.dart             # Auth API calls
│   │   ├── region_service.dart           # Region cascade API
│   │   ├── postal_code_service.dart      # Postal code auto-fill
│   │   └── upload_service.dart           # Image upload service
│   ├── models/
│   │   ├── user.dart                     # User model
│   │   ├── store.dart                    # Store model
│   │   └── region.dart                   # Province, Regency, District, Village
│   ├── data/
│   │   └── bank_list.dart                # 102+ Indonesia banks data
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart         # Login page
│   │   │   └── register_screen.dart      # Register page
│   │   ├── buyer/
│   │   │   └── home_screen.dart          # Buyer dashboard
│   │   ├── seller/
│   │   │   └── studio_screen.dart        # Studio Seniman (5 tabs)
│   │   └── shared/
│   │       ├── address_form_screen.dart  # Address management
│   │       └── add_address_screen.dart   # Add new address
│   └── widgets/
│       └── (reusable components)
├── android/                               # Android native project
├── ios/                                   # iOS native project
├── assets/                                # Images, fonts, icons
├── pubspec.yaml                           # Dependencies & assets
└── test/                                  # Unit & widget tests
```

---

## 🔐 Backend Configuration

### API Base URL:
Default: `https://majacraft.id`

**Untuk Development Lokal:**
Edit `lib/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:3001'; // Local dev server
}
```

**Android Emulator Special Cases:**
- `localhost` → gunakan `10.0.2.2` (emulator localhost alias)
- LAN server → gunakan IP address komputer (cek dengan `ipconfig` atau `ifconfig`)

### Test Accounts:
```
Email: testmobile@majacraft.id
Password: password123
Role: SELLER
KYC Status: VERIFIED
```

### External APIs:
- **Region Data:** https://www.emsifa.com/api-wilayah-indonesia/api
- **Postal Code:** https://kodepos.vercel.app

---

## ⚡ Quick Commands

```bash
# Run app (debug mode, hot reload enabled)
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with specific entry point
flutter run -t lib/main_dev.dart

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test

# Check devices
flutter devices

# List emulators
flutter emulators

# Check Flutter doctor
flutter doctor -v
```

---

## 📚 Technologies Used

- **Framework:** Flutter 3.32.6 (stable)
- **Language:** Dart SDK 3.8.1
- **State Management:** Provider (^6.1.1)
- **HTTP Client:** http (^1.2.0), http_parser (^4.0.2)
- **Image Picker:** image_picker (^1.0.7)
- **Storage:** Shared Preferences (local storage)
- **Platform:** Android (iOS coming soon)

---

## 🐛 Known Issues & Solutions

### Issue: Performance Lag at Startup
**Solution:** Implemented static cache with 5-minute TTL and `AutomaticKeepAliveClientMixin` untuk prevent multiple API calls.

### Issue: Logo Not Displaying
**Solution:** Added base URL concatenation for relative image paths dan error handler.

### Issue: Race Condition in Data Loading
**Solution:** Sequential `await` in `_initializeData()` to load provinces before restoring store data.

### Issue: Gradle Build Timeout
**Solution:**
```bash
# Edit android/gradle.properties
# Add/update:
org.gradle.jvmargs=-Xmx2048m
org.gradle.daemon=true
org.gradle.parallel=true
```

---

## 📖 Additional Resources

- **Flutter Docs:** https://docs.flutter.dev
- **Dart Docs:** https://dart.dev/guides
- **Provider Package:** https://pub.dev/packages/provider
- **Flutter DevTools:** https://docs.flutter.dev/tools/devtools
- **Android Developer:** https://developer.android.com

---

**Last Updated:** 2026-07-27  
**Flutter Version:** 3.32.6 (stable)

### Issue: SDK Version Mismatch di Expo Go
**Solution:** Pakai local development build (`npx expo run:android`) bukan Expo Go

### Issue: AsyncStorage Deprecated Warning
**Status:** False alarm, `@react-native-async-storage/async-storage` adalah package yang benar

### Issue: React 19 Peer Dependency
**Solution:** Install dengan flag `--legacy-peer-deps`

---

## 📞 Support

**Repository:** https://github.com/krismayuangga/majacraft-mobile
**Backend Repository:** https://github.com/krismayuangga/majacraft

Untuk pertanyaan atau issues, buka GitHub Issues di repository.

---

## 🎓 Learning Resources

- **Expo Documentation:** https://docs.expo.dev/
- **React Native:** https://reactnative.dev/docs/getting-started
- **Expo Router:** https://docs.expo.dev/router/introduction/
- **Android Development:** https://developer.android.com/docs

---

**Last Updated:** 2026-07-22
**Version:** 1.0.0
**SDK:** Expo 54
