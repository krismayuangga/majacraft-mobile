# Login dengan Google — Dokumentasi Flutter Developer

> Endpoint backend sudah tersedia dan siap digunakan.
> Dokumen ini menjelaskan cara implementasi Google Sign-In di Flutter
> yang terhubung dengan sistem autentikasi MajaCraft.

---

## Ringkasan Alur

```
Flutter app → Google Sign-In SDK → dapat idToken
  ↓
POST /api/auth/mobile/google { idToken }
  ↓
Backend verifikasi idToken ke Google
Backend cari user by email, jika belum ada → buat user baru (role: BUYER)
Backend generate JWT 30 hari
  ↓
Flutter terima { token, user }
Simpan token di secure storage
Kirim FCM token ke /api/mobile/fcm-token
  ↓
User masuk ke app (sudah login)
```

---

## Konfigurasi yang Sudah Ada di Server

**Google Client ID (Web):**

```
1089490083968-mpv497utnj95294vtjid83j8g83i0ooe.apps.googleusercontent.com
```

> ⚠️ Client ID ini adalah **Web Client ID** dari Google Console.
> Flutter membutuhkan **Android Client ID** yang terpisah.
> Lihat Bagian 1 di bawah untuk setup Android Client ID.

---

## BAGIAN 1: Setup Google Console

### 1.1 Dapatkan SHA-1 Fingerprint dari Flutter

Jalankan di terminal lokal:

```bash
# Debug (untuk development)
cd android
./gradlew signingReport

# Atau pakai keytool:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Salin nilai **SHA-1** dari output.

### 1.2 Buat Android OAuth Client di Google Console

1. Buka **<https://console.cloud.google.com>**
2. Pilih project yang sama dengan Firebase (MajaCraft)
3. Menu → **APIs & Services** → **Credentials**
4. Klik **"+ CREATE CREDENTIALS"** → **OAuth client ID**
5. Application type: **Android**
6. Package name: `id.majacraft.majacraft_mobile`
7. SHA-1: paste dari langkah 1.1
8. Klik **Create**
9. Salin **Android Client ID** yang baru dibuat

> **Catatan:** Android Client ID TIDAK perlu di-paste ke kode Flutter secara eksplisit.
> Cukup pastikan SHA-1 dan package name cocok. `google-services.json` yang sudah ada
> sudah berisi konfigurasi yang benar.

---

## BAGIAN 2: Setup Flutter

### 2.1 Tambah Dependency

Di `pubspec.yaml`:

```yaml
dependencies:
  google_sign_in: ^6.2.1
```

Jalankan: `flutter pub get`

### 2.2 Konfigurasi Android

Di `android/app/build.gradle`, pastikan ada:

```groovy
defaultConfig {
  applicationId "id.majacraft.majacraft_mobile"
  minSdk 21
  // ...
}
```

Tidak perlu menambahkan apapun ke `AndroidManifest.xml` secara manual —
package `google_sign_in` menangani ini otomatis.

---

## BAGIAN 3: Implementasi di Flutter

### 3.1 Service Google Sign-In

Buat file `lib/services/google_auth_service.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static const String _baseUrl = 'https://majacraft.id';

  /// Login dengan Google dan dapatkan JWT dari backend MajaCraft
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      // 1. Trigger Google Sign-In
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // user batal

      // 2. Ambil authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Gagal mendapatkan ID token dari Google');
      }

      // 3. Kirim idToken ke backend MajaCraft
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/mobile/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login Google gagal');
      }

      final data = jsonDecode(response.body);
      return data['data']; // { token, user }

    } catch (e) {
      rethrow;
    }
  }

  /// Logout dari Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
```

### 3.2 Panggil di Login Screen

```dart
import 'package:your_app/services/google_auth_service.dart';

// Di LoginScreen atau WelcomeScreen:

ElevatedButton.icon(
  icon: Image.asset('assets/google_logo.png', width: 20),
  label: Text('Lanjutkan dengan Google'),
  onPressed: _handleGoogleLogin,
)

Future<void> _handleGoogleLogin() async {
  setState(() => isLoading = true);
  
  try {
    final result = await GoogleAuthService.signIn();
    if (result == null) {
      // User batal
      setState(() => isLoading = false);
      return;
    }

    final String token = result['token'];
    final Map user    = result['user'];

    // Simpan ke secure storage
    await secureStorage.write(key: 'auth_token', value: token);
    await secureStorage.write(key: 'user_data',  value: jsonEncode(user));

    // Daftarkan FCM token setelah login
    await _registerFCMToken(token);

    // Navigasi ke home
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ));
    }

  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login Google gagal: $e')),
    );
  }
}

Future<void> _registerFCMToken(String authToken) async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    await http.post(
      Uri.parse('https://majacraft.id/api/mobile/fcm-token'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fcmToken': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }),
    );
  } catch (_) {} // FCM bukan blocker login
}
```

---

## BAGIAN 4: API Endpoint (sudah live di server)

### POST /api/auth/mobile/google

```http
POST https://majacraft.id/api/auth/mobile/google
Content-Type: application/json

{ "idToken": "eyJhbGciOiJSUzI1NiIsIn..." }
```

**Response sukses (200):**

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "cmrwgcfvg0000krad2q3pqil8",
      "name": "Angga Adrianto",
      "email": "angga@gmail.com",
      "image": "https://lh3.googleusercontent.com/...",
      "role": "buyer",
      "status": "ACTIVE",
      "kycStatus": "UNVERIFIED",
      "store": null
    }
  }
}
```

**Response error:**

```json
{ "success": false, "error": "Google token tidak valid atau sudah kadaluarsa" }
{ "success": false, "error": "Akun Anda telah diblokir" }
```

**Yang dilakukan backend saat Google login:**

- Verifikasi `idToken` ke server Google menggunakan `google-auth-library`
- Cari user berdasarkan email atau Google account ID
- Jika user belum ada → **buat user baru otomatis** (role: BUYER)
- Update foto profil jika belum ada
- Generate JWT valid 30 hari
- Return `{ token, user }` — format SAMA dengan `/api/mobile/auth/login`

---

## BAGIAN 5: Logout Google

Saat user logout dari app, pastikan juga logout dari Google:

```dart
Future<void> logout() async {
  // 1. Hapus FCM token di server
  await _unregisterFCMToken();

  // 2. Logout dari Google
  await GoogleAuthService.signOut();

  // 3. Hapus data lokal
  await secureStorage.deleteAll();

  // 4. Navigasi ke login
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
    (_) => false,
  );
}
```

---

## BAGIAN 6: Perbedaan Login Google vs Login Email/Password

| Aspek | Google Login | Email/Password Login |
| ------- | ------------- | --------------------- |
| Endpoint | `POST /api/auth/mobile/google` | `POST /api/mobile/auth/login` |
| Input | `idToken` (dari Google SDK) | `email` + `password` |
| JWT field | `sub` (user ID) | `userId` (user ID) |
| Auto daftar | Ya — user baru dibuat otomatis | Tidak — harus daftar dulu |
| Password | Tidak ada (null di DB) | Ada, bcrypt hash |
| Hapus akun | Bisa (tidak ada password check) | Perlu password check |

> ⚠️ User yang login via Google **tidak memiliki password**.
> Jika mencoba ganti password: endpoint `/api/users/change-password`
> akan mengembalikan error "Akun ini menggunakan login Google".

---

## BAGIAN 7: Checklist Implementasi

- [ ] Tambah `google_sign_in` ke `pubspec.yaml`
- [ ] Buat Android OAuth Client ID di Google Console dengan SHA-1 debug
- [ ] Pastikan `google-services.json` sudah ada di `android/app/`
- [ ] Buat `GoogleAuthService` dengan method `signIn()` dan `signOut()`
- [ ] Tambah tombol "Lanjutkan dengan Google" di Login Screen
- [ ] Setelah login: simpan token, daftarkan FCM token
- [ ] Setelah logout: `GoogleSignIn.signOut()` + hapus FCM token
- [ ] Test dengan akun Google yang berbeda (baru vs sudah pernah login)
- [ ] Tambah SHA-1 release key saat akan publish ke Play Store
