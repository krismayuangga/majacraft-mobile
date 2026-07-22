# MajaCraft Mobile - Local Development Guide

## 🚀 Setup untuk Build & Test Lokal

Dokumentasi lengkap untuk build dan test aplikasi di komputer lokal menggunakan Android emulator.

---

## 📋 Prerequisites

### 1. Install Node.js
- **Version:** Node.js 18.x atau 20.x
- Download: https://nodejs.org/
- Verify: `node --version` dan `npm --version`

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

### 3. Setup Environment Variables

**Windows:**
```bash
# User Variables
ANDROID_HOME = C:\Users\<YourUsername>\AppData\Local\Android\Sdk

# Path (tambahkan):
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\emulator
%ANDROID_HOME%\tools
%ANDROID_HOME%\tools\bin
```

**macOS/Linux:**
```bash
# Tambahkan ke ~/.bashrc atau ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # atau ~/Android/Sdk di Linux
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

Restart terminal setelah setup!

### 4. Install Java Development Kit (JDK)
- **Version:** JDK 17 (recommended untuk Android)
- Download: https://adoptium.net/
- Verify: `java -version`

---

## 🔧 Setup Project

### 1. Clone Repository
```bash
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile
```

### 2. Install Dependencies
```bash
npm install --legacy-peer-deps
```

**Note:** Flag `--legacy-peer-deps` diperlukan karena ada peer dependency conflicts antara React 19 dan beberapa packages.

### 3. Verify Installation
```bash
npx expo-doctor
```

Harusnya semua checks passing (warning tentang package versions bisa diabaikan untuk development).

---

## 📱 Create Android Emulator

### Via Android Studio (Recommended):
1. Buka Android Studio
2. Tools → Device Manager (atau AVD Manager)
3. Create Virtual Device → Next
4. Pilih phone: **Pixel 5** atau **Pixel 6**
5. Pilih system image: **Android 13 (API 33)** atau **Android 14 (API 34)**
6. Click "Download" jika belum ada
7. Next → Finish
8. Launch emulator dengan tombol ▶️

### Via Command Line:
```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_5_API_33
```

---

## 🎯 Run App di Emulator

### Method 1: Expo Development Build (Recommended)

**Step 1 - Build Development Client:**
```bash
npx expo run:android
```

Perintah ini akan:
- Generate native Android project di `android/`
- Build APK development
- Install di emulator
- Start Metro bundler

**Step 2 - For Subsequent Runs:**
```bash
npm start
# Lalu tekan 'a' untuk Android
```

### Method 2: Langsung via Android (Tanpa Expo)

**Generate Native Code:**
```bash
npx expo prebuild --platform android
```

**Build & Run:**
```bash
cd android
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## 🔍 Debugging

### View Logs:
```bash
# Metro Bundler logs (sudah otomatis di terminal)

# Android Logcat:
adb logcat | grep -i "ReactNative"

# atau via Android Studio:
# View → Tool Windows → Logcat
```

### Enable Developer Menu di Emulator:
- **Windows/Linux:** Ctrl + M
- **macOS:** Cmd + M
- Atau shake emulator dengan tombol keyboard

### Common Issues:

#### 1. Metro Bundler Error "Port 8081 already in use"
```bash
# Kill process using port 8081
npx kill-port 8081
# atau
taskkill /F /IM node.exe  # Windows
killall node              # macOS/Linux
```

#### 2. Emulator Not Detected
```bash
adb devices         # Cek device terhubung
adb kill-server     # Kill ADB
adb start-server    # Start ulang
```

#### 3. Build Failed
```bash
cd android
./gradlew clean     # Clean build
cd ..
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

---

## 📦 Build Production APK

### Via Expo EAS (Recommended):
```bash
# Install EAS CLI globally
npm install -g eas-cli

# Login
eas login

# Build APK
eas build --platform android --profile preview
```

### Via Gradle (Local):
```bash
cd android
./gradlew assembleRelease

# APK output:
# android/app/build/outputs/apk/release/app-release.apk
```

**Note:** Local release build butuh signing key. Untuk development, pakai EAS Build atau debug APK.

---

## 🏗️ Project Structure

```
majacraft-mobile/
├── app/                        # Expo Router pages
│   ├── _layout.tsx            # Root layout dengan AuthProvider
│   ├── index.tsx              # Splash/redirect screen
│   ├── (auth)/                # Auth screens
│   │   ├── login.tsx          # Login screen
│   │   └── register.tsx       # Register screen
│   └── (tabs)/                # Main app tabs
│       ├── _layout.tsx        # Tab navigator
│       ├── index.tsx          # Home (WebView)
│       ├── upload.tsx         # Upload product
│       ├── products.tsx       # Seller products
│       ├── orders.tsx         # Order management
│       └── profile.tsx        # User profile
├── lib/                       # Utilities
│   ├── AuthContext.tsx        # Auth state management
│   ├── auth.ts                # AsyncStorage helpers
│   └── api.ts                 # Axios HTTP client
├── constants/
│   └── config.ts              # API URLs & constants
├── types/
│   └── index.ts               # TypeScript interfaces
├── assets/                    # Images & icons
├── app.json                   # Expo configuration
├── package.json               # Dependencies
└── eas.json                   # EAS Build profiles
```

---

## 🔐 Backend Configuration

### API Base URL:
Default: `http://72.61.208.189:3001`

**Untuk Development Lokal:**
Edit `constants/config.ts`:
```typescript
const DEV_API_URL = 'http://192.168.1.100:3001';  // Ganti dengan IP lokal
```

**Android Emulator Special Cases:**
- `localhost` → gunakan `10.0.2.2` (emulator localhost alias)
- LAN server → gunakan IP address komputer (cek dengan `ipconfig` atau `ifconfig`)

### Test Accounts:
```
Email: testmobile@majacraft.id
Password: password123
```

(Atau register account baru di app)

---

## ⚡ Quick Commands

```bash
# Start development server
npm start

# Run on Android emulator
npm run android

# Run on iOS simulator (macOS only)
npm run ios

# Clear cache & restart
npm start -- --clear

# Type check
npx tsc --noEmit

# Lint
npm run lint  # (jika configured)
```

---

## 📚 Technologies Used

- **Framework:** Expo SDK 54 + React Native 0.81.5
- **Language:** TypeScript 5.9.2
- **Navigation:** Expo Router v6
- **State Management:** React Context API
- **Storage:** AsyncStorage
- **HTTP Client:** Axios
- **UI Components:** React Native core components
- **Camera/Image:** expo-image-picker, expo-camera
- **Notifications:** expo-notifications
- **WebView:** react-native-webview

---

## 🐛 Known Issues & Solutions

### Issue: Splash Screen Stuck
**Solution:** Sudah fixed dengan menghapus splash config di `app.json`

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
