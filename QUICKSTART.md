# 🚀 Quick Start - Build & Run Lokal

## Setup Cepat untuk Testing di Emulator

### 1️⃣ Install Prerequisites

**Node.js:**
```bash
# Download dari nodejs.org (versi 18 atau 20)
node --version  # Verify
```

**Android Studio:**
- Download: https://developer.android.com/studio
- Install, buka Android Studio
- Tools → SDK Manager → Install Android 13/14

**Set Environment Variables (Windows):**
```
ANDROID_HOME = C:\Users\<Username>\AppData\Local\Android\Sdk
Path += %ANDROID_HOME%\platform-tools
Path += %ANDROID_HOME%\emulator
```

### 2️⃣ Clone & Install

```bash
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile
npm install --legacy-peer-deps
```

### 3️⃣ Create Emulator

**Android Studio:**
- Tools → Device Manager
- Create Device → Pixel 5 → Android 13 → Finish
- Launch emulator ▶️

### 4️⃣ Run App

```bash
# Method 1: Expo Development Build (Recommended)
npx expo run:android

# Method 2: Start Metro, lalu tekan 'a'
npm start
```

**Tunggu 2-5 menit untuk build pertama kali.**

### 5️⃣ Test App

- App otomatis terbuka di emulator
- Test login/register
- Test upload, orders, profile

### ✅ Done!

**Troubleshooting:**
```bash
# Port sudah dipakai:
npx kill-port 8081

# Emulator tidak terdeteksi:
adb devices

# Clear cache:
npm start -- --clear
```

**Backend API:**
- Default: http://72.61.208.189:3001
- Ganti di `constants/config.ts` kalau perlu

**Test Account:**
- Email: testmobile@majacraft.id
- Password: password123
