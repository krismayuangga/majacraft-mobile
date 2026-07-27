# Fitur Pembelian — Dokumentasi Lengkap untuk Flutter Developer

> Dokumen ini mencakup seluruh alur pembelian di MajaCraft: Keranjang → Pengiriman → Checkout → Pembayaran → Pesanan.
> Termasuk integrasi RajaOngkir (ongkir) dan iPaymu (payment gateway).

---

## ALUR PEMBELIAN LENGKAP

```
1. Buyer pilih produk → Tambah ke Keranjang
   ↓
2. Buka Keranjang → Pilih item yang mau dibeli
   ↓
3. Pilih Alamat Pengiriman
   ↓
4. Hitung Ongkir (RajaOngkir API)
   ↓
5. Buat Pesanan (POST /api/orders)
   ↓
6. Buat Pembayaran iPaymu (POST /api/payment/create)
   ↓
7. Buyer diarahkan ke URL payment iPaymu (WebView atau browser)
   ↓
8. Setelah bayar → iPaymu callback → order status: PROCESSING
   ↓
9. Seller kemas → input resi → order status: SHIPPED
   ↓
10. Buyer konfirmasi terima → order status: COMPLETED
    (atau auto-complete setelah 3 hari)
```

---

## BAGIAN 1: KERANJANG

### Aturan Keranjang

- **Timer 20 menit**: item otomatis dihapus dari keranjang setelah 20 menit sejak ditambahkan
- **Stok real-time**: jika stok habis atau produk nonaktif, item otomatis dihapus
- **Terjual offline**: produk yang di-mark sold offline otomatis dihapus dari keranjang
- Item di keranjang tidak reserve stok — stok dikurangi saat pesanan dibuat

### 1.1 GET /api/cart — Ambil isi keranjang

```http
GET /api/cart
Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "data": {
    "id": "cart-id",
    "userId": "user-id",
    "items": [
      {
        "id": "cart-item-id",
        "cartId": "cart-id",
        "productId": "product-id",
        "qty": 2,
        "addedAt": "2026-07-27T10:00:00Z",  ← untuk timer 20 menit
        "product": {
          "id": "product-id",
          "name": "Patung Ganesha",
          "slug": "patung-ganesha",
          "price": 450000,
          "originalPrice": 600000,
          "stock": 5,
          "weight": 1500,
          "isActive": true,
          "isSoldOffline": false,
          "images": [{ "url": "/uploads/products/xxx.jpg", "isPrimary": true }],
          "store": { "name": "Toko Batu Jogja", "province": "DI Yogyakarta" }
        }
      }
    ]
  }
}
```

> **Timer di Flutter:** Hitung sisa waktu dari `addedAt`. Setelah 20 menit, panggil ulang `GET /api/cart` — item akan hilang otomatis dari response.

### 1.2 POST /api/cart — Tambah item

```http
POST /api/cart
Authorization: Bearer <token>
Content-Type: application/json

{ "productId": "product-id", "qty": 1 }

Response 200: { "success": true, "data": { ...cart-item... } }
Error 400: { "error": "Stok tidak mencukupi (tersisa 2)" }
```

### 1.3 PATCH /api/cart — Update qty item

```http
PATCH /api/cart
Authorization: Bearer <token>
Content-Type: application/json

{ "cartItemId": "cart-item-id", "qty": 3 }

Response 200: { "success": true, "data": { ...updated-item... } }
```

### 1.4 DELETE /api/cart — Hapus item

```http
DELETE /api/cart
Authorization: Bearer <token>
Content-Type: application/json

{ "cartItemId": "cart-item-id" }

Response 200: { "success": true }
```

---

## BAGIAN 2: ALAMAT PENGIRIMAN

Sebelum checkout, buyer harus memilih alamat. Gunakan API alamat yang sudah ada.

```http
GET /api/addresses
Authorization: Bearer <token>

Response: list semua alamat buyer
```

Jika belum punya alamat → tampilkan form tambah alamat:

```http
POST /api/addresses
{ label, name, phone, address, city, province, district, village, zip }
```

---

## BAGIAN 3: HITUNG ONGKIR (RajaOngkir)

### Cara Kerja

Server otomatis mengambil:

- **Origin** → kota toko seller (dari `cart.items[0].product.store.city`)
- **Destination** → kota buyer (dari `addressId` yang dipilih)
- **Weight** → total berat semua item di keranjang (gram)

Flutter cukup kirim `addressId`.

### 3.1 POST /api/shipping/cost — Hitung ongkir

```http
POST /api/shipping/cost
Authorization: Bearer <token>
Content-Type: application/json

{ "addressId": "address-id" }

Response 200:
{
  "success": true,
  "data": {
    "origin": { "city": "Kota Yogyakarta", "id": 444 },
    "destination": { "city": "Kota Jakarta Selatan", "id": 152 },
    "weight": 3000,
    "couriers": [
      {
        "courier": "jne",
        "service": "REG",
        "description": "Layanan Reguler",
        "cost": 28000,
        "etd": "2-3"
      },
      {
        "courier": "jne",
        "service": "YES",
        "description": "Yakin Esok Sampai",
        "cost": 65000,
        "etd": "1-1"
      },
      {
        "courier": "jnt",
        "service": "REG",
        "description": "J&T Reguler",
        "cost": 25000,
        "etd": "2-3"
      },
      {
        "courier": "sicepat",
        "service": "BEST",
        "description": "Best",
        "cost": 23000,
        "etd": "2-3"
      }
    ]
  }
}
```

> **ETD** = Estimasi tiba dalam hari kerja

**Error yang mungkin:**

```json
{ "error": "Data kota toko seller belum diisi. Seller perlu melengkapi profil toko (Kota/Provinsi)." }
{ "error": "Keranjang kosong" }
{ "error": "Alamat tidak ditemukan" }
```

### Tampilan di Flutter

Tampilkan daftar kurir dari `couriers` sebagai pilihan:

```
○ JNE REG    — Rp 28.000  (2-3 hari)
○ JNE YES    — Rp 65.000  (1 hari)
● J&T REG    — Rp 25.000  (2-3 hari)  ← dipilih
○ SiCepat    — Rp 23.000  (2-3 hari)
```

Simpan pilihan: `{ courierName: "jnt", courierService: "REG", shippingCost: 25000 }`

---

## BAGIAN 4: BUAT PESANAN (CHECKOUT)

### 4.1 POST /api/orders — Buat pesanan baru

```http
POST /api/orders
Authorization: Bearer <token>
Content-Type: application/json

{
  "addressId": "address-id",
  "courierName": "jnt",
  "courierService": "REG",
  "shippingCost": 25000,
  "paymentMethod": "ipaymu",
  "note": "Mohon dikemas dengan bubble wrap",
  "items": [
    { "productId": "product-id-1", "qty": 1 },
    { "productId": "product-id-2", "qty": 2 }
  ]
}
```

> **PENTING:** `items` bisa diambil dari keranjang (semua item) atau sebagian (beli langsung dari detail produk).

**Fields:**

- `addressId` → wajib, id alamat pengiriman
- `courierName` → wajib, nama kurir (jne, jnt, sicepat, dsb) — **huruf kecil**
- `courierService` → wajib, layanan (REG, YES, BEST, dsb) — **huruf besar**
- `shippingCost` → wajib, hasil dari API ongkir
- `paymentMethod` → wajib, gunakan `"ipaymu"`
- `note` → opsional, catatan untuk seller
- `items` → wajib, array `{ productId, qty }`

**Response 201:**

```json
{
  "success": true,
  "data": {
    "id": "order-id",
    "orderNumber": "MC-20260727-XXXX",
    "status": "PENDING_PAYMENT",
    "subtotal": 900000,
    "shippingCost": 25000,
    "platformFee": 0,
    "discount": 0,
    "total": 925000,
    "paymentDeadline": "2026-07-27T11:30:00Z",
    "courierName": "jnt",
    "courierService": "REG"
  }
}
```

> **`paymentDeadline`**: 30 menit dari waktu pesanan dibuat. Tampilkan countdown timer.

---

## BAGIAN 5: PEMBAYARAN (iPaymu)

### Cara Kerja iPaymu

1. Flutter buat pesanan → dapat `orderId`
2. Flutter request payment URL → dapat `paymentUrl`
3. Flutter buka `paymentUrl` di WebView atau browser
4. Buyer pilih metode bayar (transfer bank, QRIS, dll) di halaman iPaymu
5. Setelah bayar → iPaymu kirim callback ke server → status pesanan diupdate ke `PROCESSING`
6. Flutter cek status pesanan secara polling

### 5.1 POST /api/payment/create — Buat URL pembayaran

```http
POST /api/payment/create
Authorization: Bearer <token>
Content-Type: application/json

{ "orderId": "order-id" }

Response 200:
{
  "success": true,
  "data": {
    "url": "https://sandbox.ipaymu.com/payment/xxx",
    "sessionId": "ipaymu-session-id",
    "orderId": "order-id"
  }
}
```

> **Gunakan `url`** ini untuk buka WebView atau InAppBrowser di Flutter.

**Error yang mungkin:**

```json
{ "error": "Konfigurasi payment gateway belum lengkap", "status": 500 }
{ "error": "Pesanan tidak dalam status menunggu pembayaran" }
```

### 5.2 Buka WebView Pembayaran di Flutter

```dart
// Setelah dapat payment URL
Navigator.push(PaymentWebViewScreen(
  paymentUrl: paymentData.url,
  orderId: paymentData.orderId,
  onPaymentComplete: () {
    // Cek status pesanan
    checkOrderStatus(paymentData.orderId);
  }
));
```

Intercept URL redirect untuk deteksi pembayaran selesai:

```dart
// iPaymu akan redirect ke: https://majacraft.id/pesanan?ref=ORDER_ID
// saat pembayaran berhasil
onNavigationRequest: (request) {
  if (request.url.contains('/pesanan?ref=')) {
    // Pembayaran selesai, navigasi ke detail pesanan
    Navigator.pop();
    goToOrderDetail(orderId);
  }
}
```

### 5.3 GET /api/payment/check/[orderId] — Cek status pembayaran

```http
GET /api/payment/check/order-id
Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "data": {
    "status": "PROCESSING",
    "orderNumber": "MC-20260727-XXXX"
  }
}
```

**Gunakan untuk polling** setelah buyer kembali dari halaman iPaymu:

```dart
// Polling setiap 3 detik, maks 60 detik
for (var i = 0; i < 20; i++) {
  await Future.delayed(Duration(seconds: 3));
  final status = await checkPaymentStatus(orderId);
  if (status != 'PENDING_PAYMENT') break;
}
```

---

## BAGIAN 6: DAFTAR & DETAIL PESANAN

### 6.1 GET /api/orders — Daftar pesanan

```http
GET /api/orders
Authorization: Bearer <token>

GET /api/orders?status=PROCESSING    ← filter by status

Response 200:
{
  "success": true,
  "data": [
    {
      "id": "order-id",
      "orderNumber": "MC-20260727-XXXX",
      "status": "PROCESSING",
      "subtotal": 900000,
      "shippingCost": 25000,
      "platformFee": 0,
      "total": 925000,
      "courierName": "jnt",
      "courierService": "REG",
      "trackingNumber": null,
      "createdAt": "2026-07-27T10:00:00Z",
      "paidAt": "2026-07-27T10:05:00Z",
      "shippedAt": null,
      "items": [
        {
          "id": "item-id",
          "productName": "Patung Ganesha",
          "price": 450000,
          "qty": 2,
          "product": {
            "id": "product-id",
            "images": [{ "url": "/uploads/products/xxx.jpg" }]
          }
        }
      ],
      "address": { "city": "Jakarta Selatan", "province": "DKI Jakarta" },
      "disputes": []
    }
  ]
}
```

**Filter status yang valid:**

```
PENDING_PAYMENT → Belum Bayar (ada countdown timer)
PROCESSING      → Dikemas Seller
SHIPPED         → Dikirim
DELIVERED       → Diterima
COMPLETED       → Selesai
CANCELLED       → Dibatalkan
REFUNDED        → Di-refund
```

**Auto-logic di server saat GET /api/orders:**

- Pesanan `PENDING_PAYMENT` yang sudah lewat `paymentDeadline` → otomatis `CANCELLED`
- Pesanan `SHIPPED`/`DELIVERED` lebih dari 3 hari tanpa komplain → otomatis `COMPLETED`

### 6.2 GET /api/orders/[id] — Detail pesanan

```http
GET /api/orders/order-id
Authorization: Bearer <token>

Response 200: detail lengkap pesanan + address + items + disputes
```

### 6.3 POST /api/orders/[id]/confirm — Konfirmasi barang diterima

```http
POST /api/orders/order-id/confirm
Authorization: Bearer <token>

Response 200: { "success": true }
```

Hanya berlaku untuk pesanan berstatus `DELIVERED` atau `SHIPPED`.
Setelah konfirmasi → status: `COMPLETED`, escrow dirilis ke seller.

### 6.4 POST /api/orders/[id]/cancel — Batalkan pesanan

```http
POST /api/orders/order-id/cancel
Authorization: Bearer <token>

Response 200: { "success": true }
```

Hanya berlaku untuk pesanan `PENDING_PAYMENT`.

---

## BAGIAN 7: TRACKING PENGIRIMAN

```http
GET /api/orders/[id]/tracking
Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "data": {
    "source": "live",
    "courierName": "J&T Express",
    "courierService": "REG",
    "trackingNumber": "JP1234567890",
    "status": "DELIVERED",
    "delivered": true,
    "lastUpdate": "2026-07-30T14:00:00Z",
    "events": [
      {
        "datetime": "2026-07-30T14:00:00Z",
        "description": "Paket telah diterima",
        "city": "Jakarta Selatan"
      },
      {
        "datetime": "2026-07-29T10:00:00Z",
        "description": "Paket sedang dalam pengiriman",
        "city": "Jakarta"
      }
    ]
  }
}
```

---

## BAGIAN 8: BELI LANGSUNG (BUY NOW) — Tanpa Keranjang

Untuk fitur "Beli Sekarang" dari halaman produk tanpa masuk keranjang:

```dart
// Langsung ke checkout dengan 1 item
final orderResponse = await createOrder({
  addressId: selectedAddress.id,
  courierName: selectedCourier.name,
  courierService: selectedCourier.service,
  shippingCost: selectedCourier.cost,
  paymentMethod: "ipaymu",
  items: [{ productId: product.id, qty: 1 }]
});
```

---

## BAGIAN 9: ALUR LENGKAP DI FLUTTER (PSEUDOCODE)

```dart
// ─── STEP 1: Tambah ke Keranjang ─────────────────────────────────────────
await addToCart(productId: product.id, qty: 1);

// ─── STEP 2: Ambil Keranjang ──────────────────────────────────────────────
final cart = await getCart();
// Tampilkan items, hitung subtotal
final subtotal = cart.items.fold(0, (sum, i) => sum + i.product.price * i.qty);

// ─── STEP 3: Pilih Alamat ─────────────────────────────────────────────────
final addresses = await getAddresses();
final selectedAddress = addresses.first; // atau dari picker

// ─── STEP 4: Hitung Ongkir ────────────────────────────────────────────────
final shipping = await calculateShipping(addressId: selectedAddress.id);
// Tampilkan daftar kurir, biarkan user pilih
final selectedCourier = shipping.couriers[userPickedIndex];

// ─── STEP 5: Konfirmasi Pesanan ───────────────────────────────────────────
// Tampilkan ringkasan: items + ongkir + total
final total = subtotal + selectedCourier.cost;

// ─── STEP 6: Buat Pesanan ────────────────────────────────────────────────
final order = await createOrder(
  addressId: selectedAddress.id,
  courierName: selectedCourier.courier,
  courierService: selectedCourier.service,
  shippingCost: selectedCourier.cost,
  paymentMethod: "ipaymu",
  items: cart.items.map((i) => { productId: i.productId, qty: i.qty }).toList(),
);
// order.status = "PENDING_PAYMENT"
// Simpan order.paymentDeadline untuk countdown timer

// ─── STEP 7: Buat Pembayaran ─────────────────────────────────────────────
final payment = await createPayment(orderId: order.id);
// payment.url = URL halaman iPaymu

// ─── STEP 8: Buka Halaman Pembayaran ─────────────────────────────────────
openPaymentWebView(url: payment.url, orderId: order.id);

// ─── STEP 9: Cek Status Pembayaran (setelah WebView tutup) ───────────────
for (var i = 0; i < 20; i++) {
  await delay(3000);
  final status = await checkPaymentStatus(orderId: order.id);
  if (status.status != 'PENDING_PAYMENT') {
    navigateToOrderDetail(orderId: order.id);
    break;
  }
}
```

---

## RINGKASAN SEMUA API PEMBELIAN

| Method | Endpoint | Fungsi |
| -------- | ---------- | -------- |
| GET | `/api/cart` | Ambil isi keranjang |
| POST | `/api/cart` | Tambah item ke keranjang |
| PATCH | `/api/cart` | Update qty item |
| DELETE | `/api/cart` | Hapus item dari keranjang |
| GET | `/api/addresses` | List alamat pengiriman |
| POST | `/api/addresses` | Tambah alamat baru |
| POST | `/api/shipping/cost` | Hitung ongkir (RajaOngkir) |
| POST | `/api/orders` | Buat pesanan baru |
| GET | `/api/orders` | List semua pesanan |
| GET | `/api/orders?status=X` | Filter pesanan by status |
| GET | `/api/orders/[id]` | Detail pesanan |
| POST | `/api/orders/[id]/confirm` | Konfirmasi barang diterima |
| POST | `/api/orders/[id]/cancel` | Batalkan pesanan |
| GET | `/api/orders/[id]/tracking` | Tracking pengiriman |
| POST | `/api/payment/create` | Buat URL pembayaran iPaymu |
| GET | `/api/payment/check/[orderId]` | Cek status pembayaran |

---

## CATATAN PENTING UNTUK FLUTTER

1. **Payment menggunakan WebView** — iPaymu tidak menyediakan SDK Flutter. Gunakan `webview_flutter` atau `flutter_inappwebview`.

2. **Intercept redirect URL** untuk deteksi pembayaran selesai:
   - Success redirect: `https://majacraft.id/pesanan?ref=ORDER_ID`
   - Cancel redirect: `https://majacraft.id/checkout?cancel=ORDER_ID`

3. **Polling status pesanan** — tidak ada webhook ke Flutter. Setelah WebView tertutup, polling `GET /api/payment/check/[id]` setiap 3 detik.

4. **Countdown timer keranjang** — item dihapus setelah 20 menit. Hitung dari `item.addedAt`. Tampilkan warning jika tinggal < 5 menit.

5. **Auto-cancel** — pesanan yang belum dibayar dalam 30 menit (`paymentDeadline`) otomatis CANCELLED saat user buka list pesanan.

6. **Ongkir origin** = kota toko seller. Jika seller belum isi kota di profil toko, API akan error. Tampilkan pesan yang sesuai.

7. **Total pesanan** = `subtotal + shippingCost + platformFee - discount`. Platform fee saat ini 0, tidak dipotong saat checkout (dipotong saat pencairan seller).

8. **iPaymu sandbox** — server saat ini menggunakan sandbox (`https://sandbox.ipaymu.com`). Payment di sandbox tidak membutuhkan uang nyata.

9. **Beli Langsung (Buy Now)** — kirim `items` di body order langsung, tidak perlu lewat keranjang.

10. **Konfirmasi penerimaan** — setelah konfirmasi, status COMPLETED dan **dana otomatis dirilis ke seller**. Ingatkan user bahwa tindakan ini tidak bisa dibatalkan.
