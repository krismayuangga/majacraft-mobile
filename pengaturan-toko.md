# Pengaturan Toko — Dokumentasi Lengkap untuk Flutter Developer

> Halaman ini menjelaskan **Tab Pengaturan Toko** yang ada di `/studio` secara menyeluruh:
> semua field, alur, validasi, dan API yang digunakan.

---

## Overview

Tab Pengaturan Toko terbagi menjadi **2 section utama:**

1. **Form Info Toko** — nama, deskripsi, logo, alamat pickup kurir
2. **Rekening Pencairan Dana** — bank, nomor rekening, nama pemilik *(disimpan dengan verifikasi OTP)*

> ⚠️ **PENTING:** Info toko dan rekening bank disimpan **terpisah** dengan mekanisme yang berbeda.

---

## SECTION 1 — Info Toko

### 1.1 Logo Toko

**Tampilan:**

- Thumbnail logo 64×64px (rounded)
- Tombol "Upload Logo"
- Tombol "Hapus Logo" (muncul jika sudah ada logo)

**Alur Upload Logo:**

```
User pilih file gambar
→ Preview langsung ditampilkan (FileReader, base64)
→ Upload ke /api/upload (multipart/form-data, folder: "logos")
→ Dapat URL → disimpan di storeForm.logoUrl
→ Saat submit form utama → URL logo ikut disimpan ke DB
```

**Validasi:**

- Format: JPG / PNG / WebP
- Ukuran max: 10MB

**API:**

```
POST /api/upload
Headers: Authorization: Bearer <token>
Body: multipart/form-data
  - file: <file gambar>
  - folder: "logos"

Response:
{ "success": true, "data": { "url": "/uploads/logos/filename.jpg" } }
```

---

### 1.2 Nama Toko

- **Label:** NAMA TOKO *
- **Type:** Text input
- **Wajib:** Ya
- **Placeholder:** "Nama studio/toko Anda"
- **Contoh:** "Test Gallery", "Batik Nusantara Jogja"

---

### 1.3 Deskripsi Toko

- **Label:** DESKRIPSI TOKO
- **Type:** Textarea (3 baris)
- **Wajib:** Tidak
- **Placeholder:** "Ceritakan tentang toko dan karya Anda..."

---

### 1.4 Alamat Pickup Kurir

**Penjelasan:**
> Digunakan kurir untuk pickup barang dari seller. **TIDAK ditampilkan ke pembeli.**

Ini adalah alamat fisik toko/studio seller yang digunakan untuk:

- Kalkulasi ongkir
- Titik pickup kurir

**Fields (cascading dropdown — isi berurutan):**

| Field | Label | Wajib | Keterangan |
| ------- | ------- | ------- | ------------ |
| `province` | Provinsi | Ya | Dropdown, pilih provinsi |
| `city` | Kota/Kabupaten | Ya | Dropdown, muncul setelah provinsi dipilih |
| `district` | Kecamatan | Tidak | Dropdown, muncul setelah kota dipilih |
| `village` | Kelurahan/Desa | Tidak | Dropdown, muncul setelah kecamatan dipilih |
| `address` | Alamat Jalan Lengkap | Ya | Text input, "cth: Jl. Mawar No. 50 RT 03/RW 02" |
| `postalCode` | Kode Pos | Ya | Text input, hanya angka |
| `phone` | No. HP (untuk kurir pickup) | Tidak | Text input |

**Fitur Tambahan:**

- Tombol **"Temukan di Peta"** → auto-detect koordinat dari alamat yang diisi
- Interaksi peta untuk pin lokasi manual

**Data dari API wilayah Indonesia** (RajaOngkir / Komerce):

```
GET /api/provinces      → list provinsi
GET /api/cities?provinceId=xxx    → list kota
GET /api/districts?cityId=xxx     → list kecamatan
GET /api/villages?districtId=xxx  → list kelurahan
```

> **Catatan untuk Flutter:** Gunakan dropdown cascading. Setiap level bergantung pada pilihan sebelumnya. Cek komponen `AddressForm` di web untuk referensi alur.

---

### 1.5 Simpan Info Toko

**Tombol:** "Simpan Pengaturan"

**Alur:**

```
User isi form → Klik "Simpan Pengaturan"
→ PATCH /api/studio/store
→ Body: { name, description, logoUrl, province, city, district, village, address, postalCode, phone }
→ Sukses → tampil pesan "✅ Pengaturan toko tersimpan!"
```

**API:**

```http
PATCH /api/studio/store
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Test Gallery",
  "description": "Menjual berbagai produk seni",
  "logoUrl": "/uploads/logos/1234567890-abc123.jpg",
  "province": "DKI JAKARTA",
  "city": "KOTA JAKARTA SELATAN",
  "district": "PASAR MINGGU",
  "village": "CILANDAK TIMUR",
  "address": "Jl. Ampera Raya No. 15",
  "postalCode": "12560",
  "phone": "08123456789"
}

Response 200:
{
  "success": true,
  "data": {
    "id": "...",
    "name": "Test Gallery",
    "description": "Menjual berbagai produk seni",
    "logoUrl": "/uploads/logos/...",
    "province": "DKI JAKARTA",
    "city": "KOTA JAKARTA SELATAN",
    "district": "PASAR MINGGU",
    "village": "CILANDAK TIMUR",
    "address": "Jl. Ampera Raya No. 15",
    "postalCode": "12560",
    "phone": "08123456789",
    "bankName": "BCA",
    "bankAccount": "1234567890",
    "bankHolder": "Angga Adrianto",
    "isVerified": false,
    "rating": 0,
    "totalSold": 0
  }
}
```

> ⚠️ **Field bank (bankName, bankAccount, bankHolder) TIDAK disimpan melalui form ini.**
> Rekening bank disimpan lewat flow OTP terpisah (Section 2).

---

## SECTION 2 — Rekening Pencairan Dana 🔒

### Penjelasan

Rekening bank seller digunakan saat pencairan saldo. Karena menyangkut keuangan, perubahan rekening **wajib diverifikasi dengan OTP** yang dikirim ke email seller.

### 2.1 Field Rekening

| Field | Label | Keterangan |
| ------- | ------- | ------------ |
| `bankName` | Bank | Pilih dari daftar bank Indonesia |
| `bankAccount` | Nomor Rekening | Input angka |
| `bankHolder` | Atas Nama | Nama sesuai buku tabungan |

**Daftar Bank yang tersedia:**
BCA, BRI, BNI, Mandiri, BSI, CIMB Niaga, Permata, Danamon, BTN, Maybank, OCBC, Panin, BNI Syariah, dan lainnya.

---

### 2.2 Alur Verifikasi OTP untuk Ubah Rekening

```
STEP 1: User isi/ubah data rekening (bank, nomor, nama)

STEP 2: Klik "Kirim OTP ke Email"
→ POST /api/auth/otp/send
→ Body: { type: "bank_change" }
→ OTP 6 digit dikirim ke email seller
→ Berlaku 10 menit

STEP 3: User masukkan OTP yang diterima di email

STEP 4: Klik "Simpan Rekening"
→ PATCH /api/studio/store
→ Body: { bankName, bankAccount, bankHolder, otp, otpType: "bank_change" }
→ Server verifikasi OTP → jika valid → simpan rekening
→ Sukses → tampil notifikasi berhasil
```

**API Step 2 — Kirim OTP:**

```http
POST /api/auth/otp/send
Authorization: Bearer <token>
Content-Type: application/json

{ "type": "bank_change" }

Response 200:
{ "success": true, "data": { "message": "OTP dikirim ke email Anda" } }
```

**API Step 4 — Simpan Rekening dengan OTP:**

```http
PATCH /api/studio/store
Authorization: Bearer <token>
Content-Type: application/json

{
  "bankName": "BCA",
  "bankAccount": "1234567890",
  "bankHolder": "Angga Adrianto",
  "otp": "123456",
  "otpType": "bank_change"
}

Response 200:
{ "success": true, "data": { ... store data ... } }

Response 400 (OTP salah):
{ "success": false, "error": "OTP tidak valid" }

Response 400 (OTP expired):
{ "success": false, "error": "OTP sudah kadaluarsa" }
```

---

### 2.3 Kapan OTP Wajib?

OTP **WAJIB** saat:

- Menambah rekening baru (belum pernah set rekening)
- Mengubah nomor rekening yang sudah ada
- Mengubah nama bank
- Mengubah nama pemilik rekening

OTP **TIDAK diperlukan** saat:

- Update info toko (nama, deskripsi, alamat, logo)

---

## GET Data Toko Saat Init Halaman

Ambil data toko untuk pre-fill semua form:

```http
GET /api/studio/store
Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "data": {
    "id": "store-id",
    "userId": "user-id",
    "name": "Test Gallery",
    "slug": "test-gallery",
    "description": "Menjual berbagai produk seni",
    "logoUrl": "/uploads/logos/...",
    "bannerUrl": null,
    "province": "DKI JAKARTA",
    "city": "KOTA JAKARTA SELATAN",
    "district": "PASAR MINGGU",
    "village": "CILANDAK TIMUR",
    "address": "Jl. Ampera Raya No. 15",
    "postalCode": "12560",
    "phone": "08123456789",
    "bankName": "BCA",
    "bankAccount": "1234567890",
    "bankHolder": "Angga Adrianto",
    "isVerified": false,
    "rating": 0,
    "totalSold": 0,
    "_count": { "products": 3 }
  }
}

Response 404:
{ "success": false, "error": "Toko tidak ditemukan" }
```

> Jika response 404, berarti user belum punya toko → arahkan ke flow "Upgrade ke Seniman"

---

## Info Fee Platform (Banner di Atas Form)

Di atas form pengaturan toko, terdapat **banner informasi fee** yang ditampilkan untuk transparansi:

| Info | Nilai |
| ------ | ------- |
| Upload & Publish | **Gratis** |
| Fee Transaksi | **2.5%** (dipotong saat pencairan) |
| Sertifikat Digital | **Gratis** |

**Contoh perhitungan:**
> Karya terjual Rp 1.000.000 → saat dicairkan, diterima Rp 975.000 (fee 2.5% = Rp 25.000 dipotong saat pencairan)

---

## Ringkasan Semua API Pengaturan Toko

| Method | Endpoint | Fungsi | Auth |
| -------- | ---------- | -------- | ------ |
| GET | `/api/studio/store` | Ambil data toko untuk pre-fill form | Bearer |
| PATCH | `/api/studio/store` | Update info toko (nama, deskripsi, alamat, logo) | Bearer |
| PATCH | `/api/studio/store` | Update rekening bank (wajib sertakan OTP) | Bearer + OTP |
| POST | `/api/upload` | Upload logo toko (multipart) | Bearer |
| POST | `/api/auth/otp/send` | Kirim OTP ke email untuk verifikasi bank | Bearer |

---

## Alur Lengkap Pengaturan Toko di Flutter

```
1. INIT SCREEN
   → GET /api/studio/store
   → Jika 404 → tampil "Belum punya toko" + tombol upgrade
   → Jika 200 → pre-fill semua form dengan data yang ada

2. SECTION 1 — INFO TOKO
   a. Opsional: upload logo
      → Pilih gambar dari galeri/kamera
      → POST /api/upload (multipart, folder: "logos")
      → Preview langsung, simpan URL

   b. Isi/edit: nama toko, deskripsi

   c. Pilih alamat (cascading dropdown):
      Provinsi → Kota → Kecamatan → Kelurahan → Alamat → Kode Pos → HP

   d. Klik "Simpan Pengaturan"
      → PATCH /api/studio/store (tanpa bank fields)
      → Tampil success/error toast

3. SECTION 2 — REKENING BANK (terpisah dari Section 1)
   a. User isi/ubah: nama bank, nomor rekening, nama pemilik

   b. Klik "Kirim OTP"
      → POST /api/auth/otp/send { type: "bank_change" }
      → Tampil field input OTP
      → Countdown 10 menit

   c. User masukkan OTP dari email

   d. Klik "Simpan Rekening"
      → PATCH /api/studio/store { bankName, bankAccount, bankHolder, otp, otpType: "bank_change" }
      → Sukses → tampil toast berhasil
      → Error OTP → tampil pesan error, user bisa kirim ulang OTP
```

---

## Catatan Penting untuk Flutter Developer

1. **Upload logo DULU, baru submit form** — URL logo harus ada sebelum PATCH store

2. **Bank terpisah dari info toko** — Jangan campur submit-nya. Info toko bisa disimpan tanpa OTP. Bank wajib OTP.

3. **Alamat bersifat cascading** — Kecamatan hanya bisa diisi setelah Kota dipilih, dst. Jika user mengubah Provinsi, reset field Kota, Kecamatan, Kelurahan.

4. **OTP berlaku 10 menit** — Tambahkan countdown timer di UI. Setelah expired, user harus request OTP baru.

5. **Rekening yang tersimpan** — Tampilkan data bank yang sudah tersimpan dari `GET /api/studio/store` sebagai preview. User bisa ubah dengan flow OTP.

6. **Fee info** — Tampilkan banner info fee di atas form (Upload & Publish: Gratis, Fee 2.5%, Sertifikat: Gratis) untuk transparansi ke seller.

7. **Field `slug` otomatis** — Tidak perlu input dari user, otomatis dibuat dari nama toko oleh server.
