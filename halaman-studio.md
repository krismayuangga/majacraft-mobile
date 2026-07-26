# Halaman Studio Seniman — Dokumentasi Lengkap untuk Flutter Developer

> File ini menjelaskan secara detail semua tab, fitur, fungsi, dan API yang ada di halaman Studio (`/studio`).
> Halaman ini **hanya bisa diakses oleh user dengan role `SELLER` atau `ADMIN`**.

---

## Akses & Autentikasi

- **URL Web:** `https://majacraft.id/studio`
- **Auth:** Bearer JWT atau NextAuth session
- **Syarat:** User harus SELLER — jika masih BUYER, tampil halaman "Upgrade ke Seniman"
- **Cek role:** `GET /api/users/me` → field `role`

---

## Struktur Tab

Studio memiliki **6 tab utama:**

| Tab ID | Label | Icon |
| -------- | ------- | ------ |
| `ringkasan` | Ringkasan | Dashboard |
| `karya` | Karya Saya | Package |
| `pesanan` | Pesanan | Shopping Bag |
| `statistik` | Statistik | Bar Chart |
| `saldo` | Saldo & Pencairan | Dollar Sign |
| `pengaturan` | Pengaturan Toko | Settings |

---

## TAB 1: RINGKASAN (Dashboard)

### Fungsi

Halaman utama yang menampilkan overview toko secara singkat.

### Konten

**Stat Cards (4 kartu):**

- Total Pendapatan → nilai pesanan berstatus `COMPLETED`
- Pesanan Aktif → pesanan berstatus `PROCESSING` atau `SHIPPED`
- Karya Terdaftar → total produk + berapa yang aktif
- Rating Toko → nilai dari store.rating

**Pesanan Terbaru (5 terakhir):**

- Nomor pesanan, nama produk, total harga, status
- Tombol "Lihat Semua" → pindah ke tab Pesanan

**Karya Terbaru (5 terakhir):**

- Nama karya, harga, stok, kategori
- Tombol "Kelola Karya" → pindah ke tab Karya

**Status Toko:**

- Badge Toko Aktif & Terverifikasi / Belum Terverifikasi

### API yang digunakan

```
GET /api/studio/store
GET /api/studio/products
GET /api/studio/orders
```

---

## TAB 2: KARYA SAYA (Manajemen Produk)

### Fungsi

Seller mengelola semua produk/karya yang dimilikinya.

### Fitur

#### A. Daftar Karya

- Tabel: foto, nama, harga, stok, kategori, status, aksi
- Badge status:
  - `Aktif` → produk online
  - `Perlu Review` → baru upload, belum dikurasi admin
  - `Perlu Perbaikan` → dapat masukan dari admin
  - `Nonaktif` → dihapus/dinonaktifkan admin
  - `Terjual Offline` → stok = 0, produk dijual di luar platform

#### B. Tambah Karya Baru

Klik tombol "Tambah Karya" → muncul form:

**Fields wajib:**

- Foto produk: maks 5 foto, upload ke `/api/upload` dulu
- Nama karya (text)
- Kategori (dropdown dari `/api/categories`)
- Harga (Rp)
- Stok (angka)
- Deskripsi (textarea)

**Fields opsional:**

- Harga asli/coret (untuk diskon)
- Berat (kg → dikonversi ke gram, minimum 100g)
- Dimensi: panjang × lebar × tinggi (cm)
- Asal daerah (text)
- Kondisi: Baru / Bekas Layak
- Material/bahan
- Tags (comma-separated)

#### C. Edit Karya

- Klik ikon Edit pada baris produk → form yang sama terisi data existing

#### D. Hapus Karya

- Klik ikon Hapus → konfirmasi dialog → DELETE produk
- **Catatan:** Produk dengan riwayat pesanan tidak bisa dihapus (error 409)

#### E. Tandai Terjual Offline

- Seller bisa tandai produk yang terjual di luar marketplace
- Aksi: stok jadi 0, produk tetap tampil dengan badge "TERJUAL"
- Bisa dibatalkan (stok aktif kembali)

### API

```
GET    /api/studio/products              → list semua produk toko
POST   /api/studio/products              → buat produk baru
PATCH  /api/studio/products/[id]         → edit produk
DELETE /api/studio/products/[id]         → hapus produk
POST   /api/studio/products/[id]/sold-offline → tandai terjual offline
POST   /api/upload                       → upload foto (multipart/form-data)
GET    /api/categories                   → list kategori untuk dropdown
```

**Request POST/PATCH produk:**

```json
{
  "name": "Patung Ganesha Batu Andesit",
  "description": "Patung Ganesha buatan tangan...",
  "price": 450000,
  "originalPrice": 600000,
  "stock": 5,
  "categoryId": "...",
  "weight": 1500,
  "length": 20,
  "width": 15,
  "height": 25,
  "origin": "Yogyakarta",
  "material": "Batu Andesit",
  "kondisi": "Baru",
  "tags": ["ganesha", "batu", "antik"],
  "imageUrls": ["/uploads/products/file1.jpg", "/uploads/products/file2.jpg"]
}
```

---

## TAB 3: PESANAN (Order Management)

### Fungsi

Seller melihat dan memproses pesanan yang masuk ke toko mereka.

### Fitur

#### A. Daftar Pesanan

- Tampil semua pesanan dengan item dari toko seller
- Info: nomor pesanan, nama produk, qty, total, status, tanggal
- Badge status pesanan:
  - `PENDING_PAYMENT` → Menunggu Bayar
  - `PROCESSING` → Sedang Dikemas → **Ada tombol Input Resi**
  - `SHIPPED` → Sedang Dikirim
  - `DELIVERED` → Diterima Buyer
  - `COMPLETED` → Selesai
  - `CANCELLED` → Dibatalkan

#### B. Input Resi Pengiriman (Ship Modal)

Hanya muncul untuk pesanan berstatus `PROCESSING`.

**Fields:**

- Nama kurir (JNE, J&T, SiCepat, GoSend, dll)
- Layanan kurir (REG, YES, OKE, dll)
- Nomor resi (otomatis uppercase, hanya alfanumerik)

**Catatan:** Kurir yang dipilih buyer saat checkout ditampilkan sebagai referensi, seller bisa override.

**Setelah submit → status pesanan berubah ke `SHIPPED`**

#### C. Pesanan dengan Komplain

- Badge "Komplain Aktif" pada pesanan yang ada dispute
- Tombol "Buka Room Komplain" → navigasi ke halaman detail komplain

### API

```
GET  /api/studio/orders             → list pesanan masuk toko
POST /api/studio/orders/[id]/ship   → input resi & kirim
```

**Request ship:**

```json
{
  "trackingNumber": "JNE123456789",
  "courierName": "JNE",
  "courierService": "REG"
}
```

---

## TAB 4: STATISTIK

### Fungsi

Tampilan data analitik toko (sederhana).

### Konten

- Total produk aktif
- Total pesanan masuk
- Total pesanan selesai
- Total pendapatan bersih
- Rating rata-rata toko

> **Catatan:** Tab ini saat ini masih basic. Tidak ada chart library yang digunakan, hanya angka statistik.

### API

```
GET /api/studio/orders   → untuk hitung statistik dari data orders
GET /api/studio/products → untuk hitung total produk
```

---

## TAB 5: SALDO & PENCAIRAN

### Fungsi

Seller melihat saldo dari pesanan selesai dan mengajukan pencairan dana.

### Fitur

#### A. Ringkasan Saldo

- Gross Revenue → total pendapatan dari produk (sebelum fee)
- Fee Platform → persentase fee dipotong (default 5%)
- Ongkir Pass-through → total ongkir (tidak kena fee)
- Net Revenue → yang bisa dicairkan
- Total Sudah Dicairkan → jumlah yang pernah di-withdraw
- **Saldo Tersedia** = Net Revenue - Total Dicairkan

#### B. Riwayat Pencairan

- List history withdrawal: jumlah, fee, net, bank, status, tanggal
- Status: `PENDING`, `APPROVED`, `REJECTED`, `TRANSFERRED`

#### C. Ajukan Pencairan (PIN + OTP)

Form withdrawal dengan **verifikasi keamanan dua langkah:**

1. **Set PIN dulu** (jika belum punya PIN):
   - OTP dikirim ke email
   - Masukkan OTP → set PIN 6 digit

2. **Ajukan Pencairan:**
   - Nominal yang ingin dicairkan
   - Nama bank (pilih dari daftar)
   - Nomor rekening
   - Nama pemilik rekening
   - Masukkan PIN 6 digit untuk konfirmasi

> ⚠️ **Info rekening bank tersimpan di pengaturan toko** (`store.bankName`, `store.bankAccount`, `store.bankHolder`). Jika belum diset, ada peringatan untuk ke Pengaturan Toko.

### API

```
GET  /api/studio/balance   → data saldo, fee, riwayat
POST /api/studio/balance   → ajukan pencairan
Body: { amount, bankName, bankAccount, bankHolder, pin }

POST /api/auth/otp/send    → kirim OTP ke email untuk reset PIN
POST /api/auth/pin/set     → set PIN withdrawal baru
Body: { otp, pin }
```

**Response GET /api/studio/balance:**

```json
{
  "grossRevenue": 5000000,
  "shippingTotal": 150000,
  "feePercent": 5,
  "feeAmount": 250000,
  "netRevenue": 4900000,
  "totalWithdrawn": 2000000,
  "availableBalance": 2900000,
  "withdrawals": [
    {
      "id": "...",
      "amount": 2000000,
      "fee": 100000,
      "netAmount": 1900000,
      "status": "TRANSFERRED",
      "bankName": "BCA",
      "bankAccount": "1234567890",
      "bankHolder": "Angga Adrianto",
      "createdAt": "2026-07-20T..."
    }
  ]
}
```

---

## TAB 6: PENGATURAN TOKO

### Fungsi

Seller mengelola informasi toko dan rekening bank untuk pencairan.

### Fitur

#### A. Logo Toko

- Upload foto logo (klik area logo → pilih file)
- Format: JPG/PNG/WebP, maks 5MB
- Diupload ke `/api/upload` → URL disimpan di `store.logoUrl`

#### B. Informasi Dasar Toko

- Nama Toko (wajib)
- Deskripsi Toko (textarea)
- Nomor HP Toko (untuk kurir pickup)
- Alamat Toko:
  - Provinsi (wajib) → untuk kalkulasi ongkir
  - Kota
  - Kecamatan
  - Kelurahan
  - Alamat lengkap
  - Kode Pos

#### C. Rekening Bank (untuk Pencairan)

- Nama Bank → pilih dari daftar (BCA, BRI, BNI, Mandiri, BSI, dll)
- Verifikasi bank via OTP email sebelum simpan
- Nomor Rekening
- Nama Pemilik Rekening

> ⚠️ Mengubah rekening bank memerlukan OTP email untuk keamanan.

### API

```
GET   /api/studio/store    → ambil data toko
PATCH /api/studio/store    → simpan perubahan toko
Body: {
  name, description, phone, province, city, district, village,
  address, postalCode, bankName, bankAccount, bankHolder,
  logoUrl
}
```

---

## FITUR LINTAS TAB

### Status Verifikasi Toko

- Banner di sidebar kiri (desktop): "Toko Aktif & Terverifikasi" / "Belum Terverifikasi"
- KYC verified → bisa berjualan tanpa batas
- KYC belum verified → muncul link ke halaman KYC

### Tombol "Tambah Karya"

- Selalu tersedia di header studio (kecuali saat tab Karya sudah terbuka)
- Membuka form tambah produk baru langsung tanpa pindah tab

---

## ALUR LENGKAP SELLER

```
1. Register → Login → Upgrade ke Seniman (isi nama toko + provinsi)

2. Lengkapi profil toko:
   - Upload logo toko (opsional)
   - Set info toko (kota, alamat, HP)
   - Set rekening bank (wajib untuk pencairan)

3. Upload produk/karya:
   - Foto (maks 5)
   - Detail: nama, harga, stok, kategori, deskripsi
   - Submit → status "Perlu Review"

4. Admin review produk:
   - Disetujui → status "Aktif", produk tampil di marketplace
   - Perlu Perbaikan → notifikasi ke seller, produk masih tampil

5. Pesanan masuk:
   - Notifikasi masuk (new_order)
   - Lihat di tab Pesanan → status PROCESSING
   - Kemas barang → Input resi → status SHIPPED

6. Pesanan selesai:
   - Buyer konfirmasi terima → status COMPLETED
   - Saldo bertambah setelah dikurangi fee platform

7. Pencairan saldo:
   - Tab Saldo → lihat saldo tersedia
   - Ajukan pencairan → input PIN → kirim ke admin
   - Admin approve → transfer ke rekening → status TRANSFERRED
```

---

## SEMUA API STUDIO (RINGKASAN)

| Method | Endpoint | Fungsi |
| -------- | ---------- | -------- |
| GET | `/api/studio/store` | Data toko seller |
| PATCH | `/api/studio/store` | Update info toko |
| GET | `/api/studio/products` | List produk toko |
| POST | `/api/studio/products` | Tambah produk baru |
| PATCH | `/api/studio/products/[id]` | Edit produk |
| DELETE | `/api/studio/products/[id]` | Hapus produk |
| POST | `/api/studio/products/[id]/sold-offline` | Tandai terjual offline |
| GET | `/api/studio/orders` | List pesanan masuk |
| POST | `/api/studio/orders/[id]/ship` | Input resi & kirim |
| GET | `/api/studio/balance` | Saldo & riwayat pencairan |
| POST | `/api/studio/balance` | Ajukan pencairan |
| POST | `/api/upload` | Upload gambar (multipart) |
| GET | `/api/categories` | List kategori produk |
| POST | `/api/auth/otp/send` | Kirim OTP ke email |
| POST | `/api/auth/pin/set` | Set PIN withdrawal |
| POST | `/api/users/upgrade-seller` | Upgrade BUYER → SELLER |

**Semua endpoint studio memerlukan:**

```
Authorization: Bearer <jwt_token>
```

---

## CATATAN PENTING UNTUK FLUTTER

1. **Upload gambar dulu** sebelum submit produk:
   - `POST /api/upload` dengan multipart → dapat URL
   - Sertakan URL tersebut di field `imageUrls` array saat create/edit produk

2. **Rekening bank** disimpan di store settings, bukan di user profile

3. **PIN withdrawal** berbeda dari password login — PIN 6 digit khusus untuk approval pencairan

4. **Fee platform** diambil dari `GET /api/settings` atau langsung dari `/api/studio/balance`

5. **Status moderasi produk** bisa berubah sewaktu-waktu oleh admin — selalu refresh data saat masuk halaman

6. **Seller TIDAK BISA** mengakses pesanan user lain, hanya pesanan yang mengandung produk dari toko mereka
