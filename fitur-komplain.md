# Fitur Komplain & Dispute — Dokumentasi Flutter Developer

> Dokumentasi ini menjelaskan semua yang perlu diimplementasi di Flutter untuk fitur komplain/dispute,
> termasuk kapan tombol muncul, form pengajuan, chat room mediasi, dan semua API endpoint.

---

## RINGKASAN ALUR

```
Buyer terima pesanan (SHIPPED/DELIVERED/COMPLETED)
  ↓
Tap "Ajukan Komplain" di detail pesanan
  ↓
Isi form: alasan + deskripsi + solusi diminta + foto bukti (opsional)
  ↓
POST /api/disputes → dispute dibuat, status: PENDING_SELLER
  ↓
Seller merespons (setuju / tidak setuju)
  ↓
Jika tidak setuju → Buyer/Seller eskalasi ke Admin
  ↓
Admin mediasi di chat room (buyer + seller + admin)
  ↓
Penyelesaian:
  a. Buyer selesaikan pesanan (tidak jadi komplain)
  b. Buyer retur barang → submit resi → seller konfirmasi → admin proses refund
  c. Admin konfirmasi transfer manual selesai
```

---

## BAGIAN 1: TOMBOL DI HALAMAN DETAIL PESANAN

### 1.1 Logika Tampilan Tombol

```dart
// Kondisi untuk setiap tombol:

// KONFIRMASI PENERIMAAN
bool showConfirm = order.status == 'SHIPPED' || order.status == 'DELIVERED';

// AJUKAN KOMPLAIN (hanya jika belum ada komplain aktif)
final activeStatuses = ['PENDING_SELLER', 'SELLER_RESPONDED', 'IN_MEDIATION',
                        'REFUND_PENDING', 'REFUND_FAILED'];
bool hasActiveDispute = order.disputes?.any(
  (d) => activeStatuses.contains(d['status'])
) ?? false;

bool showComplain = !hasActiveDispute &&
    ['SHIPPED', 'DELIVERED', 'COMPLETED'].contains(order.status);

// BUKA ROOM MEDIASI (jika sudah ada komplain)
bool showOpenDispute = order.disputes?.any(
  (d) => d['status'] != 'CANCELLED'
) ?? false;

// BERI ULASAN (order selesai)
bool showReview = order.status == 'COMPLETED';
```

### 1.2 Tampilan Tombol per Status

| Status Order | Tombol yang Muncul |
| --- | --- |
| `SHIPPED` | Konfirmasi Penerimaan + Ajukan Komplain (jika belum ada) |
| `DELIVERED` | Konfirmasi Penerimaan + Ajukan Komplain (jika belum ada) |
| `COMPLETED` | Beri Ulasan + Ajukan Komplain (jika belum ada) |
| Semua (jika sudah ada komplain) | Buka Room Mediasi |

### 1.3 Update Model Order — Tambah Field `disputes`

Pastikan response `GET /api/orders/{id}` sudah di-parse dengan field `disputes`:

```json
{
  "id": "order-id",
  "status": "SHIPPED",
  "disputes": [
    {
      "id": "dispute-id",
      "status": "PENDING_SELLER",
      "disputeNumber": "DSP-20260727-00001",
      "createdAt": "2026-07-27T..."
    }
  ]
}
```

```dart
class Order {
  final String id;
  final String status;
  final List<DisputeSummary>? disputes;
  // ... field lainnya
}

class DisputeSummary {
  final String id;
  final String status;
  final String disputeNumber;
  final String createdAt;
}
```

---

## BAGIAN 2: FORM AJUKAN KOMPLAIN

### 2.1 Fields Form

Tampilkan sebagai bottom sheet atau halaman baru:

**1. Alasan Komplain (required, dropdown)**

```dart
final Map<String, String> reasons = {
  'NOT_AS_DESCRIBED': 'Tidak sesuai deskripsi',
  'DAMAGED':          'Rusak/cacat',
  'INCOMPLETE':       'Tidak lengkap',
  'NOT_RECEIVED':     'Tidak diterima',
  'WRONG_ITEM':       'Barang salah',
  'FAKE_PRODUCT':     'Produk palsu',
  'OTHER':            'Lainnya',
};
```

**2. Deskripsi (required, textarea, min 20 karakter)**

**3. Solusi Diminta (required, dropdown)**

```dart
final Map<String, String> actions = {
  'REFUND_FULL':    'Refund penuh',
  'REFUND_PARTIAL': 'Refund sebagian',
  'REPLACEMENT':    'Ganti barang',
  'RETURN_REFUND':  'Retur + refund',
  'REPAIR':         'Perbaikan',
};
```

**4. Foto Bukti (opsional, max 5 foto)**

- Upload ke `/api/upload` dulu (multipart, folder: "evidence")
- Simpan URL-nya, masukkan ke `evidenceUrls`

### 2.2 API Submit Komplain

```http
POST /api/disputes
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderId": "order-id",
  "reason": "NOT_AS_DESCRIBED",
  "description": "Warna produk sangat berbeda dengan foto yang ditampilkan di marketplace.",
  "requestedAction": "REFUND_FULL",
  "evidenceUrls": ["/uploads/evidence/foto1.jpg"]
}

Response 201:
{
  "success": true,
  "data": {
    "disputeNumber": "DSP-20260727-00001",
    "dispute": {
      "id": "dispute-id",
      "status": "PENDING_SELLER"
    }
  }
}
```

**Setelah berhasil:** navigasi ke DisputeChatScreen dengan `disputeId` dari response.

---

## BAGIAN 3: SCREEN CHAT ROOM MEDIASI (DisputeChatScreen)

### 3.1 Data yang Ditampilkan

Ambil semua data dari satu endpoint:

```http
GET /api/disputes/{disputeId}
Authorization: Bearer <token>

Response 200:
{
  "id": "dispute-id",
  "disputeNumber": "DSP-20260727-00001",
  "status": "IN_MEDIATION",
  "reason": "NOT_AS_DESCRIBED",
  "description": "Warna tidak sesuai",
  "requestedAction": "REFUND_FULL",
  "resolution": null,
  "refundAmount": null,

  "returnTrackingNumber": null,
  "returnCourier": null,
  "returnShippedAt": null,
  "returnReceivedAt": null,

  "order": {
    "orderNumber": "MC-xxx",
    "total": 8800000,
    "status": "SHIPPED",
    "items": [{ "productName": "...", "price": 8500000, "qty": 1 }]
  },
  "buyer":  { "id": "...", "name": "Angga Adrianto", "image": null },
  "seller": { "id": "...", "name": "Kinerja Craft",  "image": null },
  "assignedAdmin": { "id": "...", "name": "Admin MajaCraft", "image": null },

  "messages": [
    {
      "id": "msg-id",
      "senderRole": "BUYER",
      "isSystemMsg": false,
      "message": "Warna sangat berbeda!",
      "createdAt": "2026-07-27T10:00:00Z",
      "sender": { "name": "Angga Adrianto", "image": null }
    },
    {
      "id": "sys-msg-id",
      "senderRole": "ADMIN",
      "isSystemMsg": true,
      "message": "Komplain telah dieskalasi ke admin",
      "createdAt": "2026-07-27T10:30:00Z"
    }
  ],

  "timeline": [
    { "action": "created",   "description": "Komplain diajukan",      "createdAt": "..." },
    { "action": "escalated", "description": "Dieskalasi ke mediasi",   "createdAt": "..." }
  ]
}
```

### 3.2 Render Pesan Chat

```dart
// Render berbeda per senderRole dan isSystemMsg:

Widget buildMessage(Map msg, String currentUserId) {
  final isSystem = msg['isSystemMsg'] == true;
  final role     = msg['senderRole'];    // BUYER, SELLER, ADMIN
  final isOwn    = (role == 'BUYER'  && currentUser.isBuyer) ||
                   (role == 'SELLER' && currentUser.isSeller);

  if (isSystem) {
    // Chip/badge di TENGAH layar
    return Center(child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(msg['message'], style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
    ));
  }

  // Bubble chat
  final isAdmin = role == 'ADMIN';
  return Align(
    alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isOwn
            ? Color(0xFFB45309)         // amber-700 → pesan sendiri
            : isAdmin
                ? Color(0xFFEDE9FE)     // violet-100 → admin/mediator
                : Color(0xFFF5F5F4),    // stone-100 → seller
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Label pengirim (hanya untuk pesan orang lain)
        if (!isOwn) Row(children: [
          Text(msg['sender']['name'],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11,
                             color: isAdmin ? Colors.purple.shade700 : Colors.black54)),
          if (isAdmin) Text(' • Mediator',
            style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
        ]),
        SizedBox(height: isOwn ? 0 : 4),
        Text(msg['message'],
          style: TextStyle(
            color: isOwn ? Colors.white : Colors.black87,
            fontSize: 14,
          )),
        SizedBox(height: 4),
        Text(formatTime(msg['createdAt']),
          style: TextStyle(fontSize: 10, color: isOwn ? Colors.white60 : Colors.black38)),
      ]),
    ),
  );
}
```

### 3.3 Kirim Pesan

```http
POST /api/disputes/{disputeId}/messages
Authorization: Bearer <token>
Content-Type: application/json

{ "message": "Teks pesan di sini" }

Response 201:
{
  "success": true,
  "data": {
    "id": "new-msg-id",
    "senderRole": "BUYER",
    "message": "...",
    "isSystemMsg": false,
    "createdAt": "...",
    "sender": { "name": "Angga", "image": null }
  }
}
```

### 3.4 Polling Real-time (tidak ada WebSocket)

```dart
Timer? _pollTimer;

@override
void initState() {
  super.initState();
  fetchDispute();
  // Polling setiap 5 detik saat screen aktif
  _pollTimer = Timer.periodic(Duration(seconds: 5), (_) {
    if (mounted) fetchDispute();
  });
}

@override
void dispose() {
  _pollTimer?.cancel();
  super.dispose();
}
```

---

## BAGIAN 4: TOMBOL AKSI DI CHAT ROOM

Tampilkan tombol berdasarkan kondisi dari data dispute:

### 4.1 Eskalasi ke Admin (Buyer/Seller)

```dart
bool showEscalate = dispute.status == 'SELLER_RESPONDED' &&
                    !(dispute.sellerAgreed ?? false);

// Tombol: "Eskalasi ke Admin"
// Aksi:
POST /api/disputes/{disputeId}/escalate
{ "reason": "Tidak sepakat dengan penjual" }
```

### 4.2 Form Input Resi Retur (Buyer)

> **PENTING:** Form resi hanya muncul jika buyer memang memilih **Retur + Refund** (`RETURN_REFUND`)
> sebagai solusi. Untuk Refund Penuh / Refund Sebagian / Ganti Barang — tidak perlu retur,
> jadi form ini TIDAK ditampilkan.

```dart
// Tampil ketika:
// 1. Buyer adalah current user
// 2. requestedAction == 'RETURN_REFUND'  ← HANYA ini (bukan cek reason)
// 3. Belum ada resi retur yang disubmit
// 4. Status bukan PENDING_SELLER (seller harus respons dulu), CLOSED, atau CANCELLED
// 5. Order belum REFUNDED
bool showReturnForm = isBuyer &&
    dispute.requestedAction == 'RETURN_REFUND' &&
    dispute.returnTrackingNumber == null &&
    !['PENDING_SELLER', 'CLOSED', 'CANCELLED'].contains(dispute.status) &&
    order.status != 'REFUNDED';

// Form fields:
// - Nama kurir (text input, contoh: JNE, J&T, SiCepat)
// - Nomor resi retur (text input, uppercase)
// - Penanggung ongkir: BUYER / SELLER (dropdown)

// Aksi:
PATCH /api/disputes/{disputeId}
{
  "action": "submit_return_tracking",
  "courier": "JNE",
  "trackingNumber": "JNE123456789",
  "shippingPayer": "BUYER"
}
```

### 4.3 Konfirmasi Barang Retur Diterima (Seller)

```dart
bool showConfirmReturn = isSeller &&
    dispute.returnTrackingNumber != null &&
    dispute.returnReceivedAt == null &&
    order.status != 'REFUNDED';

// Tombol: "Konfirmasi Barang Retur Diterima"
// Aksi:
PATCH /api/disputes/{disputeId}
{ "action": "confirm_return_received" }
```

### 4.4 Selesaikan Pesanan (Buyer — tidak jadi komplain / deal selesai)

> Tombol ini memberi pembeli pilihan untuk **menutup dispute dan merilis dana ke penjual**,
> misalnya jika masalah sudah diselesaikan lewat chat atau buyer memilih tidak komplain lebih lanjut.
>
> **Tidak ditampilkan** jika buyer sudah mengirim retur (`returnTrackingNumber` sudah ada),
> karena tidak masuk akal merilis dana ke penjual setelah barang dikembalikan.

```dart
// Tampil ketika:
// 1. Buyer adalah current user
// 2. Order masih aktif: SHIPPED atau DELIVERED
// 3. Dispute belum selesai/tutup/batal
// 4. Buyer BELUM mengirim retur (returnTrackingNumber masih null)
//    → Kalau sudah kirim retur, tidak boleh selesaikan pesanan
bool showComplete = isBuyer &&
    ['SHIPPED', 'DELIVERED'].contains(order.status) &&
    !['RESOLVED', 'CLOSED', 'CANCELLED'].contains(dispute.status) &&
    dispute.returnTrackingNumber == null; // ← Jangan tampilkan kalau sudah ada resi retur

// Tombol: "Selesaikan Pesanan"
// Tampilkan konfirmasi dialog sebelum eksekusi:
// "Yakin selesaikan pesanan? Dana akan dilepas ke penjual."

// Aksi:
POST /api/orders/{orderId}/confirm
// orderId = ID pesanan (bukan dispute ID)
```

### 4.5 Info Resi Retur (tampil setelah buyer submit resi)

```dart
// Jika dispute.returnTrackingNumber sudah ada, tampilkan info retur (read-only):
bool showReturnInfo = dispute.returnTrackingNumber != null;

// Tampilkan:
// - Kurir retur: dispute.returnCourier
// - Nomor resi: dispute.returnTrackingNumber
// - Penanggung ongkir: dispute.returnShippingPayer ("BUYER" / "SELLER")
// - Tanggal kirim: dispute.returnShippedAt (jika ada)
// - Diterima seller: dispute.returnReceivedAt (jika ada, berarti barang sudah sampai)
// - Link cek resi: https://cekresi.com/?noresi={trackingNumber}
```

### 4.6 Ringkasan Logika Tombol

Berikut tabel untuk memudahkan implementasi. Perhatikan bahwa satu dispute bisa menampilkan
beberapa tombol sekaligus (mis. buyer melihat "Selesaikan Pesanan" + kotak info alur refund).

| Kondisi requestedAction | Tombol untuk Buyer | Tombol untuk Seller | Tombol untuk Admin |
| --- | --- | --- | --- |
| `REFUND_FULL` / `REFUND_PARTIAL` | ✅ Selesaikan Pesanan (jika order aktif) | — | ✅ Proses Refund (via chat room web) |
| `RETURN_REFUND` (belum ada resi) | ✅ Selesaikan Pesanan + ✅ Form Input Resi (setelah seller respons) | — | — |
| `RETURN_REFUND` (resi sudah ada, belum diterima) | ❌ Tidak ada | ✅ Konfirmasi Terima Retur | — |
| `RETURN_REFUND` (retur diterima) | — | — | ✅ Proses Refund (via chat room web) |
| Semua (status SELLER_RESPONDED, seller tidak setuju) | ✅ Eskalasi ke Admin | ✅ Eskalasi ke Admin | — |

---

## BAGIAN 5: STATUS DISPUTE & ARTINYA

| Status | Label UI | Keterangan |
| -------- | ---------- | ------------ |
| `PENDING_SELLER` | Menunggu Penjual | Seller belum merespons |
| `SELLER_RESPONDED` | Penjual Merespons | Seller sudah balas, belum sepakat |
| `IN_MEDIATION` | Mediasi Admin | Admin bergabung |
| `REFUND_PENDING` | Refund Diproses | Buyer sudah submit resi retur |
| `REFUND_FAILED` | Refund Gagal | Proses refund gagal |
| `RESOLVED` | Selesai | Komplain selesai |
| `CLOSED` | Ditutup | Ditutup tanpa aksi |
| `CANCELLED` | Dibatalkan | Dibatalkan buyer |

---

## BAGIAN 6: SEMUA API ENDPOINT DISPUTE

| Method | Endpoint | Fungsi | Auth |
| -------- | ---------- | -------- | ------ |
| POST | `/api/disputes` | Buat komplain baru | Bearer |
| GET | `/api/disputes/{id}` | Detail dispute + semua pesan + timeline | Bearer |
| POST | `/api/disputes/{id}/messages` | Kirim pesan di chat room | Bearer |
| POST | `/api/disputes/{id}/escalate` | Eskalasi ke admin | Bearer |
| POST | `/api/disputes/{id}/cancel` | Batalkan komplain | Bearer |
| PATCH | `/api/disputes/{id}` | Submit resi retur / konfirmasi terima | Bearer |
| POST | `/api/upload` | Upload foto bukti (multipart, folder: "evidence") | Bearer |

---

## BAGIAN 7: CHECKLIST IMPLEMENTASI

- [ ] Update model `Order` — tambah field `disputes: List<DisputeSummary>`
- [ ] Di `OrderDetailScreen` — tambah logika tombol berdasarkan status + dispute
- [ ] Buat `ComplainFormScreen` atau bottom sheet dengan form komplain
- [ ] Buat `DisputeChatScreen` dengan:
  - [ ] Header info komplain (nomor, status, alasan, aksi diminta)
  - [ ] List pesan dengan render berbeda per role (buyer/seller/admin/system)
  - [ ] Input text + tombol kirim
  - [ ] Polling setiap 5 detik
  - [ ] **Tombol "Selesaikan Pesanan"** — muncul untuk buyer jika order SHIPPED/DELIVERED dan belum ada resi retur (lihat 4.4)
  - [ ] **Tombol "Eskalasi ke Admin"** — muncul saat SELLER_RESPONDED & seller tidak setuju (4.1)
  - [ ] **Form Input Resi Retur** — HANYA untuk requestedAction == RETURN_REFUND, setelah seller respons (4.2)
  - [ ] **Info Resi Retur (read-only)** — tampil setelah resi disubmit (4.5)
  - [ ] **Tombol "Konfirmasi Terima Retur"** — untuk seller setelah buyer submit resi (4.3)
- [ ] Handle upload foto bukti di form komplain
- [ ] Konfirmasi dialog sebelum aksi destruktif (selesaikan pesanan, eskalasi)

### Bug yang Perlu Diperbaiki di Kode Flutter Existing

Jika sudah ada implementasi `DisputeChatScreen`, cek dan perbaiki kondisi berikut:

```dart
// ❌ SALAH - menyebabkan form retur muncul untuk semua komplain kecuali NOT_RECEIVED
bool showReturnForm = isBuyer &&
    (dispute.requestedAction == 'RETURN_REFUND' || dispute.reason != 'NOT_RECEIVED') && ...

// ✅ BENAR - hanya muncul untuk RETURN_REFUND
bool showReturnForm = isBuyer &&
    dispute.requestedAction == 'RETURN_REFUND' &&
    dispute.returnTrackingNumber == null &&
    !['PENDING_SELLER', 'CLOSED', 'CANCELLED'].contains(dispute.status) &&
    order.status != 'REFUNDED';

// ❌ SALAH - tidak mengecek apakah retur sudah dikirim
bool showComplete = isBuyer &&
    ['SHIPPED', 'DELIVERED'].contains(order.status) &&
    !['RESOLVED', 'CLOSED', 'CANCELLED'].contains(dispute.status);

// ✅ BENAR - sembunyikan jika buyer sudah kirim retur
bool showComplete = isBuyer &&
    ['SHIPPED', 'DELIVERED'].contains(order.status) &&
    !['RESOLVED', 'CLOSED', 'CANCELLED'].contains(dispute.status) &&
    dispute.returnTrackingNumber == null;
```
