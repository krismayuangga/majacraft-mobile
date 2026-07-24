# MajaCraft Mobile — Quickstart (Pure React Native CLI)

## Prerequisites

| Tool | Version | Link |
|------|---------|------|
| Node.js | 18+ | https://nodejs.org |
| JDK | 17 | https://adoptium.net |
| Android Studio | latest | https://developer.android.com/studio |
| React Native CLI | latest | `npm install -g react-native-cli` |

---

## 1. Setup Android Studio

Buka Android Studio → SDK Manager → install:
- Android SDK Platform 34
- Android SDK Build-Tools
- Android Emulator
- Android SDK Platform-Tools

Set environment variables:
```bash
# Windows
ANDROID_HOME = C:\Users\<user>\AppData\Local\Android\Sdk
# tambahkan ke PATH: %ANDROID_HOME%\platform-tools, %ANDROID_HOME%\emulator

# macOS / Linux (~/.bashrc atau ~/.zshrc)
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
```

---

## 2. Init Project React Native

```bash
# Inisialisasi project RN CLI baru (hanya sekali)
npx react-native@0.78.2 init MajaCraftMobile \
  --template react-native-template-typescript \
  --version 0.78.2

# Masuk ke folder
cd MajaCraftMobile

# Copy seluruh konten src/ dari repo ini
# ATAU clone langsung dari repo ini ke folder tersebut
```

Jika clone dari repo ini:
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
