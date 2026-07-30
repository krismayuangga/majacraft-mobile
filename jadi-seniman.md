# Alur Jadi Seniman — Dokumentasi Flutter Developer

> Dokumen ini menjelaskan dua jalur user untuk upgrade akun dari Buyer menjadi Seller (Seniman),
> termasuk form, validasi, API, dan logika screen Studio.

---

## Dua Jalur Masuk ke Form Upgrade

### JALUR 1 — Dari Halaman Akun (tab bawah "Akun")

```
User buka tab Akun
  → Di header kartu profil ada tombol "Jadi Seniman" (hanya muncul jika role = BUYER)
  → Tap tombol → muncul Dialog/BottomSheet "Upgrade ke Seniman"
  → User isi form: Nama Toko + Pilih Provinsi
  → Tap "Upgrade Sekarang"
  → POST /api/users/upgrade-seller
  → Berhasil → update role lokal → tampil sebagai Seniman
```

### JALUR 2 — Dari Tab Studio (tab bawah "Studio")

```
User tap tab Studio di bottom navigation
  → Jika role masih BUYER:
     Tampil halaman "Studio Seniman" kosong
     dengan tombol "🚀 Upgrade ke Seniman"
  → Tap tombol → muncul Dialog/BottomSheet yang SAMA dengan Jalur 1
  → User isi form: Nama Toko + Pilih Provinsi
  → Tap "Upgrade Sekarang"
  → POST /api/users/upgrade-seller
  → Berhasil → langsung tampil Studio Dashboard (role berubah ke SELLER)
```

> **Penting:** Kedua jalur menggunakan **satu dialog/widget yang sama**. Buat sebagai
> widget reusable `UpgradeToSellerDialog` agar tidak duplikasi kode.

---

## Form Upgrade — Fields

| Field | Label | Tipe | Wajib | Keterangan |
| --- | --- | --- | --- | --- |
| `storeName` | Nama Toko / Studio | Text input | Ya | Min 3 karakter, harus unik |
| `province` | Provinsi Asal | Dropdown | Ya | Pilih dari list di bawah |

### List Provinsi

```dart
final List<String> provinces = [
  "DKI Jakarta", "Jawa Barat", "Jawa Tengah", "Jawa Timur",
  "DI Yogyakarta", "Banten", "Bali", "Sumatera Utara",
  "Sumatera Barat", "Sumatera Selatan", "Kalimantan Timur",
  "Sulawesi Selatan", "NTB", "NTT", "Aceh", "Lainnya",
];
```

---

## API Endpoint

```http
POST /api/users/upgrade-seller
Authorization: Bearer <token>
Content-Type: application/json

{
  "storeName": "Kerajinan Batu Jogja",
  "province": "DI Yogyakarta"
}
```

**Response sukses (200):**

```json
{
  "success": true,
  "data": {
    "id": "store-id",
    "name": "Kerajinan Batu Jogja",
    "slug": "kerajinan-batu-jogja",
    "province": "DI Yogyakarta",
    "userId": "...",
    "isActive": true,
    "isVerified": false
  }
}
```

**Response error:**

```json
{ "success": false, "error": "Nama toko sudah digunakan" }
{ "success": false, "error": "Anda sudah memiliki toko" }
```

---

## Implementasi Dialog Flutter

```dart
// lib/widgets/upgrade_to_seller_dialog.dart

class UpgradeToSellerDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const UpgradeToSellerDialog({required this.onSuccess});

  @override
  State<UpgradeToSellerDialog> createState() => _UpgradeToSellerDialogState();
}

class _UpgradeToSellerDialogState extends State<UpgradeToSellerDialog> {
  final _storeNameController = TextEditingController();
  String? _selectedProvince;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _provinces = [
    "DKI Jakarta", "Jawa Barat", "Jawa Tengah", "Jawa Timur",
    "DI Yogyakarta", "Banten", "Bali", "Sumatera Utara",
    "Sumatera Barat", "Sumatera Selatan", "Kalimantan Timur",
    "Sulawesi Selatan", "NTB", "NTT", "Aceh", "Lainnya",
  ];

  Future<void> _submit() async {
    final storeName = _storeNameController.text.trim();
    if (storeName.isEmpty) {
      setState(() => _errorMessage = "Nama toko wajib diisi");
      return;
    }
    if (storeName.length < 3) {
      setState(() => _errorMessage = "Nama toko minimal 3 karakter");
      return;
    }
    if (_selectedProvince == null) {
      setState(() => _errorMessage = "Pilih provinsi asal");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final token = await SecureStorage.getToken();
      final response = await http.post(
        Uri.parse('https://majacraft.id/api/users/upgrade-seller'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'storeName': storeName,
          'province': _selectedProvince,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update role di local storage
        await SecureStorage.updateUserRole('seller');
        Navigator.pop(context); // tutup dialog
        widget.onSuccess();     // callback untuk refresh parent screen
      } else {
        setState(() => _errorMessage = data['error'] ?? 'Gagal upgrade akun');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Upgrade ke Seniman', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('Isi data studio Anda untuk mulai berjualan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal,
                           color: Colors.grey[600])),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Input Nama Toko
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NAMA TOKO / STUDIO *',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                               color: Color(0xFFB45309), letterSpacing: 0.5)),
            SizedBox(height: 6),
            TextField(
              controller: _storeNameController,
              decoration: InputDecoration(
                hintText: 'cth: Kerajinan Batu Jogja',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),

          SizedBox(height: 16),

          // Dropdown Provinsi
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PROVINSI ASAL *',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                               color: Color(0xFFB45309), letterSpacing: 0.5)),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedProvince,
              hint: Text('Pilih provinsi...'),
              items: _provinces.map((p) => DropdownMenuItem(
                value: p, child: Text(p),
              )).toList(),
              onChanged: (v) => setState(() => _selectedProvince = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),

          // Error message
          if (_errorMessage != null) ...[
            SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB45309)),
          child: _isLoading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : Text('Upgrade Sekarang', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
```

---

## Cara Panggil Dialog dari Kedua Jalur

```dart
// Fungsi reusable — panggil dari mana saja
void showUpgradeDialog(BuildContext context, {required VoidCallback onSuccess}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpgradeToSellerDialog(onSuccess: onSuccess),
  );
}

// ─── JALUR 1: dari halaman Akun ───────────────────────────────────────────
// Di header kartu profil, hanya tampil jika role == 'buyer':
if (user.role == 'buyer') ...[
  ElevatedButton.icon(
    icon: Icon(Icons.trending_up, size: 14),
    label: Text('Jadi Seniman'),
    onPressed: () => showUpgradeDialog(context, onSuccess: () {
      setState(() => user.role = 'seller');
      // Refresh halaman akun
    }),
  ),
]

// ─── JALUR 2: dari halaman Studio ─────────────────────────────────────────
// Screen saat user belum jadi seller:
class UpgradePromptScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('🎨', style: TextStyle(fontSize: 60)),
        SizedBox(height: 16),
        Text('Studio Seniman',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Upgrade akun ke Seniman untuk mulai berjualan di MajaCraft.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600])),
        SizedBox(height: 24),
        ElevatedButton.icon(
          icon: Icon(Icons.rocket_launch, size: 16),
          label: Text('Upgrade ke Seniman'),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB45309)),
          onPressed: () => showUpgradeDialog(context, onSuccess: () {
            // Navigasi ke Studio Dashboard
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => StudioDashboardScreen(),
            ));
          }),
        ),
      ]),
    );
  }
}
```

---

## Logika Screen Studio (Routing Berdasarkan Role)

```dart
// Saat user buka tab Studio, cek role terlebih dahulu
class StudioScreen extends StatelessWidget {
  final User user;

  @override
  Widget build(BuildContext context) {
    if (user.role == 'seller' || user.role == 'admin') {
      return StudioDashboardScreen(); // Studio penuh
    } else {
      return UpgradePromptScreen();   // Halaman kosong + tombol upgrade
    }
  }
}
```

---

## Update Role Setelah Upgrade

Setelah berhasil upgrade, role user harus diperbarui di:

1. **Local storage** → update field `role` di data user yang tersimpan
2. **State management** → update state global user (Provider/Bloc/Riverpod)
3. **API refresh (opsional)** → panggil `GET /api/users/me` untuk data terbaru

```dart
// Cara refresh data user terbaru dari server:
GET /api/users/me
Authorization: Bearer <token>

Response:
{
  "data": {
    "role": "SELLER",  // ← sudah berubah setelah upgrade
    "store": {
      "id": "...",
      "name": "Kerajinan Batu Jogja",
      "slug": "kerajinan-batu-jogja"
    }
  }
}
```

---

## Kapan Tombol "Jadi Seniman" Ditampilkan

```dart
// Tampilkan tombol hanya jika:
bool showUpgradeButton = user.role == 'buyer' || user.role == 'BUYER';

// JANGAN tampilkan jika:
// - role sudah 'seller' atau 'SELLER'
// - role 'admin'
```
