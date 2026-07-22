# MajaCraft Mobile

Mobile application untuk MajaCraft marketplace - platform jual beli kerajinan lokal Indonesia.

## 📱 Overview

MajaCraft Mobile adalah React Native app yang dibangun dengan Expo SDK 54, menyediakan akses mobile-friendly ke platform MajaCraft dengan fitur:

- ✅ User Authentication (Login/Register)
- ✅ Browse products via WebView
- ✅ Upload & manage products (sellers)
- ✅ Order management
- ✅ User profile management
- ✅ Camera & image picker integration
- ✅ Push notifications (configured)

## 🚀 Quick Start

### For Local Development (Recommended)

**Dokumentasi Lengkap:** [LOCAL_DEVELOPMENT.md](./LOCAL_DEVELOPMENT.md)

**Quick Steps:**
```bash
# 1. Clone repo
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile

# 2. Install dependencies
npm install --legacy-peer-deps

# 3. Run on Android emulator
npx expo run:android
```

**Prerequisites:**
- Node.js 18+ or 20+
- Android Studio + Android SDK
- Android Emulator (Pixel 5 recommended)

👉 **Lihat [QUICKSTART.md](./QUICKSTART.md) untuk setup cepat!**

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](./QUICKSTART.md) | Setup cepat 5 langkah untuk mulai development |
| [LOCAL_DEVELOPMENT.md](./LOCAL_DEVELOPMENT.md) | Panduan lengkap development lokal dengan Android emulator |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System architecture, tech stack, data flow, dan patterns |

## 🏗️ Tech Stack

- **Framework:** Expo SDK 54.0.0
- **React:** 19.1.0
- **React Native:** 0.81.5
- **Language:** TypeScript 5.9.2
- **Navigation:** Expo Router 6.0.24
- **Storage:** AsyncStorage
- **HTTP Client:** Axios
- **State Management:** React Context API

## 📁 Project Structure

```
majacraft-mobile/
├── app/                    # Expo Router pages
│   ├── (auth)/            # Auth screens (login, register)
│   └── (tabs)/            # Main app tabs (home, upload, orders, profile)
├── lib/                   # Business logic & utilities
├── constants/             # Configuration
├── types/                 # TypeScript definitions
└── assets/                # Images & icons
```

## 🔌 Backend Integration

**API Base URL:** `http://72.61.208.189:3001`

Backend repository: [krismayuangga/majacraft](https://github.com/krismayuangga/majacraft)

**Test Account:**
```
Email: testmobile@majacraft.id
Password: password123
```

## 🛠️ Development Commands

```bash
# Start development server
npm start

# Run on Android emulator
npx expo run:android

# Type check
npx tsc --noEmit

# Clear cache & restart
npm start -- --clear
```

## 📦 Build Production APK

### Via EAS Build (Cloud)
```bash
npm install -g eas-cli
eas login
eas build --platform android --profile preview
```

### Via Gradle (Local)
```bash
cd android
./gradlew assembleRelease
```

APK output: `android/app/build/outputs/apk/release/app-release.apk`

## 🐛 Known Issues

### Expo Go SDK Compatibility
**Issue:** Expo Go di Play Store support SDK 54, tapi ada masalah splash screen stuck.

**Solution:** **Gunakan local development build** (`npx expo run:android`) bukan Expo Go.

### Package Version Warnings
**Issue:** npm menampilkan peer dependency warnings.

**Solution:** Install dengan flag `--legacy-peer-deps` (sudah correct).

## 📞 Support

**Issues:** https://github.com/krismayuangga/majacraft-mobile/issues

**Backend:** https://github.com/krismayuangga/majacraft

## 📄 License

MIT License - Free to use and modify

## 🙏 Credits

Developed with AI assistance (GitHub Copilot + Claude) for rapid prototyping and best practices implementation.

---

**Version:** 1.0.0  
**Last Updated:** 2026-07-22  
**Expo SDK:** 54.0.0
