# MajaCraft Mobile App

Mobile application untuk marketplace MajaCraft menggunakan React Native + Expo.

## 🎯 Arsitektur

Mobile app ini menggunakan **Hybrid Approach**:
- **60% WebView**: Untuk konten-heavy pages (browsing, detail produk, dll)
- **40% Native**: Untuk critical UX (upload, checkout, notifications)

## 📦 Tech Stack

- **Framework**: React Native (Expo SDK 57)
- **Navigation**: Expo Router (file-based routing)
- **State Management**: React Context API
- **HTTP Client**: Axios
- **Storage**: AsyncStorage
- **UI**: React Native Components + Custom Components

## 🚀 Cara Menjalankan

### Prerequisites
- Node.js 18+ (tested on v24.8.0)
- npm atau yarn
- Expo Go app di smartphone (untuk testing)
- Android Studio (untuk build Android)

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm start

# Run on Android
npm run android

# Run on iOS (macOS only)
npm run ios

# Run on web browser
npm run web
```

## 📁 Struktur Project

```
majacraft-mobile/
├── app/                      # Expo Router screens
│   ├── (auth)/              # Auth flow (login, register, OTP)
│   ├── (tabs)/              # Main app tabs
│   ├── _layout.tsx          # Root layout
│   └── index.tsx            # Splash screen
├── components/              # Reusable components
├── constants/               # App configuration
│   └── config.ts            # API endpoints & config
├── lib/                     # Core utilities
│   ├── api.ts               # API client (Axios)
│   ├── auth.ts              # Auth utilities
│   └── AuthContext.tsx      # Auth state management
├── types/                   # TypeScript types
│   └── index.ts             # Shared types
├── app.json                 # Expo configuration
├── package.json             # Dependencies
└── tsconfig.json            # TypeScript config
```

## 🔐 Authentication

Aplikasi menggunakan session-based authentication dengan flow:
1. User login dengan nomor telepon + PIN
2. Jika perlu verifikasi, sistem kirim OTP
3. Setelah verifikasi, user mendapat auth token
4. Token disimpan di AsyncStorage
5. Token digunakan untuk semua API requests

## 🌐 API Integration

API client di `lib/api.ts` otomatis:
- Inject auth token ke setiap request
- Handle error responses
- Support file upload dengan progress

Base URL:
- Development: `http://localhost:3000`
- Production: `https://majacraft.id`

## 📱 Fitur Utama (Planned)

### Phase 1 (Core Features)
- [x] Authentication (Login/Register/OTP)
- [x] WebView integration untuk browsing
- [ ] Native upload produk (foto/video)
- [ ] Native checkout flow
- [ ] Push notifications setup

### Phase 2 (Enhanced UX)
- [ ] Product listing dengan native UI
- [ ] Order management
- [ ] User profile
- [ ] Review & rating system
- [ ] Real-time notifications

### Phase 3 (Advanced Features)
- [ ] Offline mode
- [ ] In-app messaging
- [ ] Payment gateway integration
- [ ] Analytics & tracking

## 🔧 Configuration

### Android Package Name
`com.majacraft.app`

### iOS Bundle Identifier
`com.majacraft.app`

### Permissions Required
- Camera (untuk foto produk)
- Gallery/Media (untuk pilih foto/video)
- Notifications (untuk push notifications)

## 🏗️ Build untuk Production

### Android APK/AAB

```bash
# Build APK (untuk testing)
eas build --platform android --profile preview

# Build AAB (untuk Google Play Store)
eas build --platform android --profile production
```

### iOS (macOS required)

```bash
# Build untuk App Store
eas build --platform ios --profile production
```

> **Note**: Untuk build production, perlu setup EAS (Expo Application Services). Jalankan `eas login` dan `eas build:configure` terlebih dahulu.

## 📋 Deployment Checklist

### Google Play Store
- [ ] Buat akun Google Play Console
- [ ] Setup app di console (nama, deskripsi, icon, screenshots)
- [ ] Build AAB dengan `eas build`
- [ ] Upload AAB ke Play Console
- [ ] Isi privacy policy, content rating
- [ ] Submit untuk review

### Apple App Store
- [ ] Buat akun Apple Developer (macOS required)
- [ ] Setup app di App Store Connect
- [ ] Build IPA dengan `eas build`
- [ ] Upload via Transporter atau Xcode
- [ ] Submit untuk review

## 🔔 Push Notifications

Setup Expo Notifications untuk real-time alerts:

1. User beri permission saat first launch
2. App register device token ke backend
3. Backend kirim notifikasi via Expo Push API
4. App terima & tampilkan notification

## 🐛 Debugging

```bash
# Clear cache dan restart
npm run reset

# Check TypeScript errors
npx tsc --noEmit

# Check for Expo issues
npx expo-doctor
```

## 🔗 Links

- **Main Website**: https://majacraft.id
- **Backend API**: Same as website backend
- **GitHub**: (URL repository)

## 📝 License

Proprietary - MajaCraft © 2026

## 👥 Team

- **Developer**: (nama developer)
- **Designer**: (nama designer)
- **PM**: (nama PM)

---

**Status**: 🚧 In Development (Phase 1)
**Target Launch**: Q2 2026
**Last Updated**: January 22, 2026
