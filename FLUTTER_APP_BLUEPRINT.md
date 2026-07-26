# MajaCraft Flutter App — Blueprint Halaman & Fitur

> Dokumen ini mendeskripsikan **semua halaman dan fitur** yang harus dibuat ulang di Flutter native.
> Setiap halaman mencakup: fungsi, data yang ditampilkan, API endpoint, dan catatan penting.

---

## 🔐 AUTH — Autentikasi

### 1. Login Screen
**Path web:** `/masuk`

**Fitur:**
- Form email + password
- Tombol Login
- Link ke Register
- Login dengan Google (opsional, gunakan endpoint `/api/mobile/auth/google`)

**API:**
```
POST /api/mobile/auth/login
Body: { email, password }
Response: { token, user: { id, name, email, image, role } }
```

**Catatan:**
- Simpan `token` dan `user` ke local storage / secure storage
- Token valid 7 hari
- Role: `"buyer"` atau `"seller"`

---

### 2. Register Screen
**Path web:** `/daftar`

**Fitur:**
- Form nama + email + password + konfirmasi password
- Tombol Daftar
- Link ke Login

**API:**
```
POST /api/mobile/auth/register
Body: { name, email, password }
Response 201: { token, user }
```

---

### 3. Lupa Password
**Path web:** `/lupa-password`

> **Catatan:** Belum ada API mobile untuk reset password. Arahkan user ke browser: `https://majacraft.id/lupa-password`

---

## 🏠 BUYER — Halaman Utama

### 4. Home / Beranda
**Path web:** `/`

**Fitur:**
- Hero banner/slider promosi
- Grid kategori (10 kategori) + jumlah produk per kategori
- Produk unggulan (featured)
- Flash Sale (produk diskon)
- Produk terbaru

**API:**
```
GET /api/categories
Response: [{ id, name, slug, icon, imageUrl, _count: { products } }]

GET /api/products?featured=true&limit=10
GET /api/products?flashSale=true&limit=10
GET /api/products?limit=20&sortBy=createdAt
```

---

### 5. Halaman Kategori
**Path web:** `/kategori`

**Fitur:**
- Grid semua kategori dengan gambar, nama, jumlah produk
- Tap kategori → masuk halaman produk filter kategori

**API:**
```
GET /api/categories
```

---

### 6. Halaman Produk (Listing)
**Path web:** `/produk`

**Fitur:**
- List / grid semua produk
- Filter: kategori, harga min/max, rating
- Sort: terbaru, harga termurah, paling laku
- Search: query teks
- Pagination / infinite scroll

**API:**
```
GET /api/products
Params: ?kategori=kerajinan-batu&limit=20&page=1&search=batik&sortBy=price&order=asc
Response: { products: [...], total, page, pages }
```

**Model Produk:**
```json
{
  "id": "...",
  "name": "Patung Ganesha",
  "slug": "patung-ganesha",
  "price": 450000,
  "originalPrice": 600000,
  "rating": 4.5,
  "reviewCount": 12,
  "soldCount": 30,
  "images": [{ "url": "...", "isPrimary": true }],
  "store": { "name": "Toko Batu", "slug": "toko-batu" },
  "category": { "name": "Kerajinan Batu" },
  "isFlashSale": false,
  "isFeatured": false
}
```

---

### 7. Detail Produk
**Path web:** `/produk/[slug]`

**Fitur:**
- Galeri foto produk (swipe)
- Nama, harga (coret jika ada diskon), rating
- Deskripsi lengkap
- Info toko + rating toko
- Spesifikasi: berat, dimensi, material, asal daerah
- Ulasan pembeli (list review + rata-rata bintang)
- Tombol: **Tambah ke Keranjang**, **Beli Langsung**
- Tombol: Wishlist (❤️)
- Share produk

**API:**
```
GET /api/products/[slug]
GET /api/reviews?productId=[id]

POST /api/cart
Body: { productId, qty }

POST /api/wishlist
Body: { productId }
```

---

### 8. Keranjang
**Path web:** `/keranjang`

**Fitur:**
- List item di keranjang (foto, nama, harga, qty)
- Ubah qty, hapus item
- Checkbox pilih item untuk checkout
- Total harga
- Tombol **Lanjut ke Checkout**

**API:**
```
GET /api/cart
POST /api/cart         Body: { productId, qty }
PATCH /api/cart        Body: { cartItemId, qty }
DELETE /api/cart       Body: { cartItemId }
```

---

### 9. Checkout
**Path web:** `/checkout`

**Fitur:**
- Pilih/tambah alamat pengiriman
- Pilih kurir + estimasi ongkir
- Ringkasan pesanan (item, subtotal, ongkir, total)
- Pilih metode pembayaran (iPaymu)
- Tombol **Bayar Sekarang** → redirect ke halaman pembayaran

**API:**
```
GET /api/addresses
POST /api/addresses    Body: { label, name, phone, address, city, province, zip }

POST /api/shipping/cost
Body: { origin, destination, weight, courier }

POST /api/payment/create
Body: { addressId, items: [{ productId, qty }], courierName, courierService }
Response: { paymentUrl, orderId }
```

**Catatan:**
- Setelah bayar, user diarahkan ke halaman sukses / pesanan

---

### 10. Lacak Pesanan (tanpa login)
**Path web:** `/lacak-pesanan`

**Fitur:**
- Input nomor pesanan
- Lihat status pengiriman

> Bisa pakai WebView untuk halaman ini

---

## 📦 PESANAN

### 11. Daftar Pesanan
**Path web:** `/pesanan`

**Fitur:**
- Tab: Semua, Belum Bayar, Diproses, Dikirim, Selesai, Dibatalkan
- Card pesanan: nomor, item, total, status, tanggal
- Tap → Detail Pesanan

**API:**
```
GET /api/orders
GET /api/orders?status=PROCESSING
Response: { orders: [...] }

Order: { id, orderNumber, status, total, createdAt, items: [...] }
```

**Status pesanan:**
```
PENDING_PAYMENT → Belum Bayar
PROCESSING      → Dikemas
SHIPPED         → Dikirim
DELIVERED       → Diterima
COMPLETED       → Selesai
CANCELLED       → Dibatalkan
REFUNDED        → Refund
```

---

### 12. Detail Pesanan
**Path web:** `/pesanan/[id]`

**Fitur:**
- Info pesanan: nomor, tanggal, status
- List produk yang dipesan
- Info pengiriman: alamat, kurir, nomor resi, tracking
- Ringkasan harga
- Tombol aksi sesuai status:
  - `PENDING_PAYMENT` → **Bayar Sekarang** (countdown timer)
  - `DELIVERED` → **Konfirmasi Diterima**, **Ajukan Komplain**
  - `COMPLETED` → **Beri Ulasan**, **Ajukan Komplain**
- Tombol **Chat dengan Penjual**

**API:**
```
GET /api/orders/[id]

POST /api/orders/[id]/confirm   → konfirmasi barang diterima
POST /api/orders/[id]/cancel    → batalkan pesanan
GET /api/orders/[id]/tracking   → data tracking pengiriman
```

---

### 13. Beri Ulasan
**Path web:** Modal di `/pesanan/[id]`

**Fitur:**
- Rating bintang (1-5)
- Teks ulasan (min 20 karakter)
- Upload foto (max 5)
- Upload video (max 50MB)
- Tombol Kirim Ulasan

**API:**
```
POST /api/reviews
Body: { orderId, productId, rating, comment, imageUrls, videoUrl }
```

---

### 14. Komplain / Dispute
**Path web:** `/pesanan/[id]/komplain/[disputeId]`

**Fitur:**
- Info komplain: alasan, solusi diminta, deskripsi
- Chat mediasi (buyer ↔ seller ↔ admin)
- Timeline proses
- Form input resi retur (jika diperlukan)
- Tombol konfirmasi sesuai role

**API:**
```
GET /api/disputes/[id]
POST /api/disputes              → buat komplain baru
POST /api/disputes/[id]/messages → kirim pesan
PATCH /api/disputes/[id]        → submit resi retur / konfirmasi
POST /api/disputes/[id]/cancel  → batalkan komplain
POST /api/disputes/[id]/escalate → eskalasi ke admin
```

---

## 👤 AKUN / PROFIL

### 15. Halaman Akun
**Path web:** `/akun`

**Fitur:**
- Avatar, nama, email
- Badge role (Pembeli / Seniman)
- Menu: Profil, Alamat, Keamanan, KYC, Notifikasi
- Jika Seller: link ke Studio
- Tombol Keluar

**API:**
```
GET /api/users/me
Response: { id, name, email, image, role, kycStatus, store }
```

---

### 16. Edit Profil
**Path web:** `/akun/profil`

**Fitur:**
- Ubah foto profil
- Ubah nama
- Ubah nomor HP

**API:**
```
PATCH /api/users/me
Body: { name, phone, image }
```

---

### 17. Alamat Pengiriman
**Path web:** `/akun/alamat`

**Fitur:**
- List alamat tersimpan
- Tambah / edit / hapus alamat
- Set alamat utama

**API:**
```
GET /api/addresses
POST /api/addresses
PATCH /api/addresses/[id]
DELETE /api/addresses/[id]
```

**Model Alamat:**
```json
{
  "id": "...",
  "label": "Rumah",
  "name": "Angga",
  "phone": "08xxx",
  "address": "Jl. Merdeka No. 1",
  "city": "Yogyakarta",
  "province": "DI Yogyakarta",
  "zip": "55111",
  "isDefault": true
}
```

---

### 18. Keamanan
**Path web:** `/akun/keamanan`

**Fitur:**
- Ubah password
- Set / ubah PIN penarikan (untuk seller)

**API:**
```
PATCH /api/users/me  Body: { currentPassword, newPassword }
POST /api/auth/pin/set
```

---

### 19. Verifikasi KYC
**Path web:** `/akun/kyc`

**Fitur:**
- Upload foto KTP
- Upload selfie + KTP
- Input NIK
- Status verifikasi (Belum, Pending, Terverifikasi, Ditolak)

**API:**
```
POST /api/users/kyc
Body: { kycNik, kycKtpUrl, kycSelfieUrl }
```

---

### 20. Notifikasi
**Path web:** `/akun/notifikasi`

**Fitur:**
- List notifikasi (ikon, judul, isi, waktu, status baca)
- Tap → navigasi ke halaman terkait
- Tandai semua dibaca

**Tipe notifikasi & navigasi:**
```
new_order           → Studio (pesanan masuk)
order_status        → Detail Pesanan /pesanan/[orderId]
dispute_*           → Halaman Komplain /pesanan/[orderId]/komplain/[disputeId]
product_moderated   → Detail Produk /produk/[slug]
product_rejected    → Studio
new_chat            → Chat
system              → Studio atau Verifikasi NFT
```

**API:**
```
GET /api/notifications?limit=50
PATCH /api/notifications         → tandai semua dibaca
PATCH /api/notifications/[id]    → tandai 1 dibaca
```

---

### 21. Wishlist
**Path web:** `/wishlist`

**Fitur:**
- Grid produk yang di-wishlist
- Hapus dari wishlist
- Tap → Detail Produk

**API:**
```
GET /api/wishlist
DELETE /api/wishlist/[productId]
```

---

## 💬 CHAT

### 22. Halaman Chat
**Path web:** `/chat`

**Fitur:**
- List percakapan (dengan penjual / produk)
- Masuk ke room chat
- Kirim pesan teks
- Context produk / pesanan

**API:**
```
GET /api/chat
GET /api/chat/[id]/messages
POST /api/chat/[id]/messages  Body: { content }
```

---

## 🏪 TOKO

### 23. Halaman Toko
**Path web:** `/toko/[slug]`

**Fitur:**
- Info toko: nama, logo, banner, deskripsi, rating, kota
- Badge Terverifikasi
- Grid produk milik toko
- Tombol Chat ke Penjual

**API:**
```
GET /api/stores/[slug]/owner
GET /api/products?storeSlug=[slug]
```

---

## 🎨 STUDIO (SELLER ONLY)

> Semua halaman Studio hanya untuk user dengan role `"seller"`

### 24. Dashboard Studio
**Path web:** `/studio`

**Fitur:**
- Ringkasan: total produk, pesanan masuk, saldo
- Pesanan masuk (perlu diproses)
- Link ke: Produk, Pencairan Saldo, Toko

---

### 25. Manajemen Produk Seller
**Path web:** `/studio` (tab produk)

**Fitur:**
- List produk milik seller
- Status: Perlu Review, Disetujui, Perlu Perbaikan, Nonaktif
- Tambah produk baru
- Edit / hapus produk

**API:**
```
GET /api/studio/products
POST /api/studio/products         → upload produk baru
PATCH /api/studio/products/[id]   → edit produk
DELETE /api/studio/products/[id]  → hapus produk
```

**Upload Produk - Fields:**
```
name, description, price, originalPrice, stock,
categoryId, weight, material, dimensions, origin,
tags, imageUrls (upload ke /api/upload dulu)
```

---

### 26. Upload Produk (Form)

**Fitur:**
- Foto produk: ambil dari kamera / galeri (max 5 foto)
- Form: nama, deskripsi, harga, stok, kategori, berat
- Validasi sebelum submit

**Upload gambar dulu:**
```
POST /api/upload
Body: FormData { file, folder: "products" }
Response: { data: { url: "https://..." } }
```

---

### 27. Pesanan Masuk (Seller)
**Path web:** `/studio` (tab pesanan)

**Fitur:**
- List pesanan yang masuk ke toko seller
- Status: Dikemas, Dikirim, Selesai
- Input nomor resi pengiriman

**API:**
```
GET /api/studio/orders
POST /api/studio/orders/[id]/ship
Body: { courierName, courierService, trackingNumber }
```

---

### 28. Saldo & Pencairan
**Path web:** `/studio` (tab keuangan)

**Fitur:**
- Tampilkan saldo tersedia (dari pesanan selesai yang belum dicairkan)
- Riwayat pencairan
- Ajukan pencairan (input nominal, pilih rekening)
- Status: Menunggu, Disetujui, Ditransfer

**API:**
```
GET /api/studio/balance
Response: {
  grossRevenue, feePercent, feeAmount,
  netRevenue, totalWithdrawn, availableBalance,
  withdrawals: [...]
}

POST /api/studio/balance
Body: { amount, bankName, bankAccount, bankHolder, otp }
```

---

### 29. Pengaturan Toko
**Path web:** `/studio` (tab toko)

**Fitur:**
- Nama toko, deskripsi, logo, banner
- Info rekening bank (untuk pencairan)
- Alamat toko / kota

**API:**
```
GET /api/studio/store
PATCH /api/studio/store
Body: { name, description, logoUrl, bannerUrl, bankName, bankAccount, bankHolder }
```

---

### 30. Upgrade ke Seller
**Path web:** `/program-seniman`

**Fitur:**
- Info program seniman MajaCraft
- Tombol **Daftar Jadi Seniman**
- Syarat: sudah KYC verified

**API:**
```
POST /api/users/upgrade-seller
Body: { storeName, province }
```

---

## 🌍 HALAMAN INFORMASI

> Halaman-halaman ini bisa menggunakan **WebView** yang mengarah ke URL web app karena kontennya statis dan tidak butuh interaksi native.

| Halaman | URL |
|---|---|
| Tentang MajaCraft | `/tentang` |
| Jaminan Keaslian | `/jaminan` |
| Syarat & Ketentuan | `/syarat` |
| Privasi & Cookie | `/privasi` |
| Bantuan Belanja | `/bantuan/belanja` |
| Bantuan Jual | `/bantuan/jual` |
| Ruang Budaya | `/ruang-budaya` |
| Download App | `/download` |

---

## 🔑 PROTECTED ENDPOINTS

Semua endpoint yang butuh login harus kirim header:
```
Authorization: Bearer <jwt-token>
```

---

## 📋 BASE URL

```
Production:  https://majacraft.id
Development: http://10.0.2.2:3030  (Android emulator)
             http://localhost:3030   (iOS simulator)
```

---

## 🗂️ RINGKASAN PRIORITAS PENGEMBANGAN

**Phase 1 — Core (wajib):**
- [ ] Login & Register
- [ ] Home (kategori + produk)
- [ ] List & Detail Produk
- [ ] Keranjang
- [ ] Checkout & Pembayaran
- [ ] Daftar & Detail Pesanan
- [ ] Akun & Profil

**Phase 2 — Engagement:**
- [ ] Notifikasi
- [ ] Chat
- [ ] Wishlist
- [ ] Ulasan Produk
- [ ] Halaman Toko

**Phase 3 — Seller:**
- [ ] Studio Dashboard
- [ ] Upload & Kelola Produk
- [ ] Kelola Pesanan (input resi)
- [ ] Saldo & Pencairan

**Phase 4 — Advanced:**
- [ ] Komplain & Dispute
- [ ] KYC Verifikasi
- [ ] Tracking Pengiriman
- [ ] Upgrade ke Seller
