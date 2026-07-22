# Testing Guide - MajaCraft Mobile App

## Prerequisites

1. **Install Expo Go** app dari Google Play Store di HP Android
2. **Pastikan HP terconnect ke internet** (tidak perlu same WiFi dengan server)
3. **Backend API running** di http://72.61.208.189:3001

## Testing Steps

### 1. Scan QR Code

Buka Expo Go app → Scan QR code yang muncul di terminal

**QR Code URL:** `exp://wd-sry4-anonymous-8081.exp.direct`

### 2. Test Register (Create New Account)

Karena sudah ada test account, bisa langsung login. Tapi bisa juga register baru:

**Fields:**
- Nama: Nama lengkap Anda
- Email: email@contoh.com
- No HP: 081234567890
- Password: min 8 karakter
- Role: Pembeli atau Seniman

### 3. Test Login

**Test Credentials:**
```
Email: testmobile@majacraft.id
Password: password123
```

### 4. Expected Behavior

**Success Flow:**
1. Splash screen muncul "MajaCraft" + loading indicator
2. Auto-navigate ke login screen (karena belum auth)
3. Setelah login success → redirect ke home screen (WebView)
4. Bottom tabs muncul: Beranda, Produk, Upload, Pesanan, Profil

**Failure Indicators:**
- Stuck di splash screen
- "Something went wrong" error
- App crash sebelum sampai login screen

## Common Issues & Solutions

### Issue: "Failed to download remote update"

**Penyebab:** HP tidak bisa connect ke Metro bundler

**Solution:** Gunakan tunnel mode (sudah di-enable)

### Issue: "Something went wrong" saat app start

**Possible Causes:**
1. JavaScript error di app code
2. Dependency missing
3. TypeScript compilation error
4. AsyncStorage error

**Debug Steps:**
1. Shake HP → pilih "Show Dev Menu" → "Reload"
2. Check error di terminal Expo
3. Enable "Show Performance Monitor" untuk melihat JS errors

### Issue: Login error "Email atau password salah"

**Solution:** Gunakan credentials yang sudah dibuat atau register baru

### Issue: Stuck di "Loading..."

**Penyebab:** AuthContext tidak bisa load user data dari AsyncStorage

**Solution:** Clear app data atau reinstall

## Backend API Status

✅ **GET /api/auth/mobile/me** - Get current user
✅ **POST /api/auth/mobile/login** - Login dengan email + password
✅ **POST /api/auth/mobile/register** - Register user baru

**Backend URL:** http://72.61.208.189:3001

## Troubleshooting

### Check Terminal Logs

Saat error muncul, cek terminal Expo untuk melihat:
- JavaScript errors
- Network errors
- Bundle errors

### Reload App

Di Expo Go:
1. Shake HP
2. Pilih "Reload"
3. Atau press R di terminal Expo

### Clear Cache

```bash
cd /root/Ecosystem/majacraft-mobile
npx expo start --clear --tunnel
```

## Contact

Jika masih error setelah semua dicoba, screenshot error dan kirim ke tim development.
