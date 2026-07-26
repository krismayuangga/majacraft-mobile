# MajaCraft Mobile — Quickstart (Flutter)

## Prerequisites

| Tool | Version | Link |
|------|---------|------|
| Flutter | 3.32.6+ | https://flutter.dev/docs/get-started/install |
| Dart SDK | 3.8.1+ | (included with Flutter) |
| Android Studio | latest | https://developer.android.com/studio |
| Android SDK | 33+ | (via Android Studio) |

---

## 1. Setup Flutter SDK

### Windows
```bash
# Download Flutter SDK
# https://docs.flutter.dev/get-started/install/windows

# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter doctor
```

### macOS
```bash
# Download Flutter SDK
# https://docs.flutter.dev/get-started/install/macos

# Extract to ~/flutter
# Add to ~/.zshrc:
export PATH="$PATH:$HOME/flutter/bin"

# Verify installation
flutter doctor
```

### Linux
```bash
# Download Flutter SDK
# https://docs.flutter.dev/get-started/install/linux

# Extract to ~/flutter
# Add to ~/.bashrc:
export PATH="$PATH:$HOME/flutter/bin"

# Verify installation
flutter doctor
```

---

## 2. Setup Android Studio

1. Open Android Studio → SDK Manager → Install:
   - ✅ Android SDK Platform 33 (Android 13)
   - ✅ Android SDK Platform 34 (Android 14)
   - ✅ Android SDK Build-Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools

2. Set environment variables:

**Windows:**
```bash
ANDROID_HOME = C:\Users\<user>\AppData\Local\Android\Sdk
# Add to PATH:
# %ANDROID_HOME%\platform-tools
# %ANDROID_HOME%\emulator
```

**macOS/Linux:**
```bash
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
export ANDROID_HOME=$HOME/Android/Sdk          # Linux
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
```

3. Accept Android licenses:
```bash
flutter doctor --android-licenses
```

---

## 3. Clone & Run Project

```bash
# 1. Clone repository
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile

# 2. Install dependencies
flutter pub get

# 3. Check connected devices
flutter devices

# 4. Run on Android emulator/device
flutter run

# Or run with specific device
flutter run -d <device-id>
```
```bash
git clone <repo-url> majacraft-mobile-source
# Salin src/, App.tsx, package.json, index.js, babel.config.js, tsconfig.json
# ke dalam folder MajaCraftMobile/
```

---

## 3. Install Dependencies

```bash
npm install

# Android native dependencies
cd android && ./gradlew clean && cd ..
```

---

## 4. Link native modules (RN 0.78 auto-link, tapi beberapa perlu manual)

### react-native-vector-icons
```bash
# Android: tambahkan ke android/app/build.gradle
apply from: "../../node_modules/react-native-vector-icons/fonts.gradle"
```

### react-native-splash-screen
```bash
# Android: ikuti panduan di https://github.com/crazycodeboy/react-native-splash-screen
```

### @notifee/react-native
```bash
# Sudah auto-link di RN 0.73+
# Tambahkan google-services.json untuk FCM di android/app/
```

---

## 5. Jalankan di Emulator

```bash
# Buka Android Studio → Device Manager → Start emulator

# Jalankan app
npm run android
# atau
npx react-native run-android
```

---

## 6. Konfigurasi URL Dev

Edit `src/constants/config.ts`:
```ts
// Android Emulator: 10.0.2.2 = localhost host machine
const DEV_HOST_ANDROID = 'http://10.0.2.2:3030';

// Physical device: ganti dengan IP LAN komputer
// const DEV_HOST_ANDROID = 'http://192.168.x.x:3030';
```

---

## Struktur App

```
src/
├── navigation/
│   ├── AppNavigator.tsx  ← Root (Auth vs Main tabs)
│   └── types.ts          ← TypeScript param types
├── screens/
│   ├── auth/
│   │   ├── LoginScreen.tsx     ← Native login (JWT)
│   │   └── RegisterScreen.tsx
│   ├── buyer/
│   │   └── HomeScreen.tsx      ← WebView (majacraft.id)
│   ├── seller/
│   │   ├── UploadScreen.tsx    ← Native (kamera + form)
│   │   └── StudioScreen.tsx    ← WebView (/studio)
│   └── shared/
│       ├── OrdersScreen.tsx    ← WebView (/pesanan)
│       └── ProfileScreen.tsx   ← Native profile
├── lib/
│   ├── api.ts          ← Axios client + JWT interceptor
│   ├── auth.ts         ← AsyncStorage helpers
│   └── AuthContext.tsx ← Global auth state
├── constants/
│   └── config.ts       ← URLs + endpoint mapping
└── types/
    └── index.ts
```

---

## Auth Flow

```
Native Login (JWT)
  → token disimpan di AsyncStorage
  → HomeScreen WebView dimuat via:
    GET /api/auth/mobile/webview-token?token=<jwt>&redirect=/
    → server buat NextAuth session cookie
    → redirect ke web app dengan user sudah login
```
