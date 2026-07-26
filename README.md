# MajaCraft Mobile

Mobile application untuk MajaCraft marketplace - platform jual beli kerajinan lokal Indonesia.

## 📱 Overview

MajaCraft Mobile adalah **Flutter application** yang menyediakan akses mobile-friendly ke platform MajaCraft dengan fitur lengkap:

### ✅ Fitur Umum
- User Authentication (Login/Register dengan JWT)
- Browse & search products (coming soon)
- Order management (coming soon)
- User profile management

### 🎨 Studio Seniman (Seller Dashboard) - **COMPLETE**
Dashboard lengkap untuk seniman/seller dengan 5 tabs:

1. **🏠 Home (Ringkasan)**: Overview toko, statistik, quick actions, KYC verification banner
2. **🎨 Karya**: Product management dengan filter (semua/aktif/nonaktif)
3. **📦 Pesanan**: Order management dengan filter status
4. **💰 Saldo**: Balance management, transaction history, withdrawal
5. **⚙️ Pengaturan**: Complete store settings:
   - Logo upload (camera/gallery) dengan auto-upload
   - Cascading address form (Provinsi→Kabupaten→Kecamatan→Desa)
   - Postal code auto-fill
   - Bank selection (102+ banks Indonesia) dengan search
   - OTP verification untuk perubahan bank
   - Fee platform info (collapsible)
   - Performance optimized (static cache, keep alive)

## 🚀 Quick Start

### Prerequisites
- **Flutter:** 3.32.6 (stable)
- **Dart SDK:** 3.8.1 or higher
- **Android Studio** + Android SDK
- **Android Emulator** atau physical device

### Installation & Run

```bash
# 1. Clone repository
git clone https://github.com/krismayuangga/majacraft-mobile.git
cd majacraft-mobile

# 2. Install dependencies
flutter pub get

# 3. Run on Android emulator/device
flutter run

# Or run with specific device
flutter devices
flutter run -d <device-id>
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [FLUTTER_APP_BLUEPRINT.md](./FLUTTER_APP_BLUEPRINT.md) | Complete Flutter app architecture & implementation blueprint |
| [pengaturan-toko.md](./pengaturan-toko.md) | Backend API documentation untuk Store Settings |
| [halaman-studio.md](./halaman-studio.md) | Studio Seniman page specifications |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System architecture & patterns |

## 🏗️ Tech Stack

- **Framework:** Flutter 3.32.6 (stable channel)
- **Language:** Dart SDK 3.8.1
- **State Management:** Provider pattern (`provider: ^6.1.1`)
- **HTTP Client:** `http: ^1.2.0` + `http_parser: ^4.0.2`
- **Image Picker:** `image_picker: ^1.0.7`
- **Platform:** Android (iOS support coming soon)

### Key Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  http: ^1.2.0              # API calls
  http_parser: ^4.0.2       # Multipart upload
  image_picker: ^1.0.7      # Image upload
```

## 📁 Project Structure

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
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── buyer/
│   │   │   └── home_screen.dart          # Buyer dashboard
│   │   ├── seller/
│   │   │   └── studio_screen.dart        # Studio Seniman main screen
│   │   └── shared/
│   │       ├── address_form_screen.dart
│   │       └── add_address_screen.dart
│   └── widgets/
│       └── (reusable components)
├── android/                               # Android native code
├── ios/                                   # iOS native code (future)
├── assets/                                # Images, icons
└── test/                                  # Unit & widget tests
```

## 🔌 Backend Integration

**API Base URL:** `https://majacraft.id`

Backend repository: [krismayuangga/majacraft](https://github.com/krismayuangga/majacraft)

### Authentication
- **Method:** JWT Bearer Token
- **Header:** `Authorization: Bearer <token>`
- **Token Expiry:** 7 days
- **Storage:** Secure local storage via Provider

### API Response Format
```json
{
  "success": true,
  "data": { ... },
  "error": "Error message (if success=false)"
}
```

### Test Account
```
Email: testmobile@majacraft.id
Password: password123
Role: SELLER
KYC Status: VERIFIED
```

### External APIs
- **Region Data:** https://www.emsifa.com/api-wilayah-indonesia/api
- **Postal Code:** https://kodepos.vercel.app

## 🛠️ Development Commands

```bash
# Run app in debug mode
flutter run

# Run with hot reload (default)
flutter run --hot

# Run on specific device
flutter run -d <device-id>

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Check devices
flutter devices

# Check Flutter doctor
flutter doctor -v
```

## 📦 Build Production APK

### Build Release APK
```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Recommended for Play Store)
```bash
# Build Android App Bundle
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

### APK Size Optimization
```bash
# Build split APKs per ABI (reduces size)
flutter build apk --split-per-abi
```

## 🎯 Features Status

### ✅ Completed
- [x] Authentication (Login/Register)
- [x] JWT token management
- [x] Studio Seniman dashboard (5 tabs)
- [x] Store settings with logo upload
- [x] Cascading address form
- [x] Postal code auto-fill
- [x] Bank selection (102+ banks with search)
- [x] OTP verification
- [x] KYC verification check
- [x] Performance optimization (caching, keep alive)

### 🚧 In Progress / Coming Soon
- [ ] Buyer home screen & product catalog
- [ ] Product detail page
- [ ] Cart & checkout flow
- [ ] Order detail & tracking
- [ ] Chat/messaging
- [ ] Push notifications
- [ ] iOS support

## 🐛 Known Issues & Solutions

### Performance at Startup
**Fixed:** Implemented static cache (5-min TTL) and `AutomaticKeepAliveClientMixin` to prevent multiple API calls when switching tabs.

### Logo Display Issue
**Fixed:** Added base URL concatenation for relative image paths and error handler for broken images.

### Race Condition in Data Loading
**Fixed:** Sequential `await` in `_initializeData()` to load provinces before restoring store data.

## 📞 Support

**Issues:** https://github.com/krismayuangga/majacraft-mobile/issues

**Backend Repository:** https://github.com/krismayuangga/majacraft

**Website:** https://majacraft.id

## 📄 License

MIT License - Free to use and modify

## 🙏 Credits

Developed with AI assistance (GitHub Copilot + Claude Sonnet 4.5) for rapid prototyping and best practices implementation.

**Key Features Developed:**
- Complete Studio Seniman seller dashboard
- Cascading region API integration
- Searchable bank picker (102+ banks)
- Image upload & multipart handling
- Performance optimization patterns
- Clean architecture with services/models/providers

---

**Version:** 2.0.0 (Flutter Migration)  
**Last Updated:** 2026-07-27  
**Flutter SDK:** 3.32.6 (stable)  
**Dart SDK:** 3.8.1
