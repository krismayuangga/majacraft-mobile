# Fitur Chat & Chat Room Komplain — Dokumentasi untuk Flutter Developer

> Fitur chat di MajaCraft terdiri dari **dua sistem chat yang berbeda** namun saling terhubung:
>
> 1. **Chat Produk/Pesanan** — percakapan langsung antara buyer dan seller
> 2. **Chat Room Komplain (Dispute Mediation)** — ruang mediasi untuk penyelesaian sengketa

---

## BAGIAN 1: CHAT PRODUK & PESANAN

### Konsep

Chat biasa digunakan untuk:

- Tanya-jawab sebelum beli (dari halaman produk)
- Komunikasi setelah pesanan (dari halaman pesanan)
- Buyer menghubungi seller tentang produk/pengiriman

Setiap chat memiliki **konteks** — bisa terhubung ke produk tertentu, ke pesanan tertentu, atau keduanya.

---

### Schema Database

```
Chat {
  id          String
  orderId     String?    // opsional — chat terkait pesanan
  productId   String?    // opsional — chat terkait produk
  createdAt   DateTime
  participants: ChatParticipant[]
  messages:    Message[]
}

Message {
  id        String
  chatId    String
  senderId  String
  content   String
  isBlocked Boolean   // pesan diblokir karena berisi kontak pribadi
  readAt    DateTime? // null = belum dibaca
  createdAt DateTime
}
```

---

### API Endpoints Chat

#### GET /api/chat — Inbox semua percakapan

```http
GET /api/chat
Authorization: Bearer <token>

Response 200:
[
  {
    "id": "chat-id",
    "orderId": "order-id atau null",
    "productId": "product-id atau null",
    "productName": "Nama produk/pesanan",
    "product": {
      "id": "...",
      "name": "Patung Ganesha",
      "slug": "patung-ganesha",
      "price": 450000,
      "image": "/uploads/products/xxx.jpg"
    },
    "otherUser": {
      "id": "user-id-lawan-bicara",
      "name": "Nama Penjual/Pembeli",
      "image": "/uploads/..."
    },
    "lastMessage": {
      "id": "msg-id",
      "content": "Isi pesan terakhir",
      "senderId": "...",
      "createdAt": "2026-07-27T..."
    },
    "unreadCount": 3,
    "createdAt": "2026-07-20T..."
  }
]
```

---

#### POST /api/chat — Buat atau temukan chat

```http
POST /api/chat
Authorization: Bearer <token>
Content-Type: application/json

{
  "targetUserId": "user-id-seller",    // WAJIB — id pemilik toko
  "productId": "product-id",           // opsional — konteks produk
  "orderId": "order-id"                // opsional — konteks pesanan
}

Response 200 (chat sudah ada): { "id": "existing-chat-id" }
Response 201 (chat baru dibuat): { "id": "new-chat-id" }
```

**Cara mendapatkan `targetUserId` seller:**

```http
GET /api/stores/[slug]/owner
Response: { "userId": "seller-user-id", "storeName": "Nama Toko" }
```

---

#### GET /api/chat/[id]/messages — Ambil riwayat pesan

```http
GET /api/chat/[id]/messages
Authorization: Bearer <token>

Response 200:
[
  {
    "id": "msg-id",
    "chatId": "chat-id",
    "senderId": "user-id",
    "content": "Halo, apakah stok masih ada?",
    "isBlocked": false,
    "readAt": null,
    "createdAt": "2026-07-27T10:00:00Z"
  }
]
```

> **Catatan:** Memanggil endpoint ini otomatis menandai semua pesan sebagai **sudah dibaca** (mengisi `readAt`).

---

#### POST /api/chat/[id]/messages — Kirim pesan

```http
POST /api/chat/[id]/messages
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Isi pesan di sini" }

Response 201:
{
  "id": "new-msg-id",
  "chatId": "chat-id",
  "senderId": "user-id",
  "content": "Isi pesan di sini",
  "isBlocked": false,
  "readAt": null,
  "createdAt": "2026-07-27T10:05:00Z"
}

Response jika pesan diblokir (berisi nomor HP / WA / Telegram):
{
  "isBlocked": true,
  "warning": "Pesan diblokir: tidak boleh membagikan kontak pribadi"
}
```

**Pesan yang akan diblokir otomatis:**

- Nomor HP / WhatsApp
- Link wa.me
- Username Telegram
- Alamat Gmail/Yahoo

---

### Alur Chat dari Halaman Produk (Tanya Penjual)

```
1. User buka halaman produk
2. Tap tombol "Chat dengan Penjual"

3. Ambil userId seller:
   GET /api/stores/[store-slug]/owner
   → dapat: { userId: "seller-id" }

4. Buat/temukan chat:
   POST /api/chat { targetUserId: "seller-id", productId: "product-id" }
   → dapat: { id: "chat-id" }

5. Navigasi ke ChatRoom screen dengan chatId

6. Load pesan:
   GET /api/chat/[chat-id]/messages

7. Kirim pesan:
   POST /api/chat/[chat-id]/messages { content: "..." }
```

---

### Alur Chat dari Halaman Pesanan

```
1. User buka detail pesanan
2. Tap tombol "Chat dengan Penjual"

3. Buat/temukan chat dengan konteks pesanan:
   POST /api/chat { targetUserId: "seller-id", orderId: "order-id" }

4. Proses sama seperti langkah 5-7 di atas
```

---

### Fitur Unread Count di Navbar

```http
GET /api/notifications?limit=1
Response: { "data": { "unreadCount": 3 } }
```

Atau dari inbox chat:

```dart
final inbox = await getChatInbox();
final totalUnread = inbox.fold(0, (sum, c) => sum + c.unreadCount);
```

---

## BAGIAN 2: CHAT ROOM KOMPLAIN (DISPUTE MEDIATION)

### Konsep

Ketika buyer mengajukan komplain terhadap pesanan, sistem membuat **ruang mediasi khusus** yang terpisah dari chat biasa. Di sini buyer, seller, dan admin berinteraksi untuk menyelesaikan sengketa.

**Perbedaan utama dengan chat biasa:**

| | Chat Biasa | Chat Room Komplain |
| --- | --- | --- |
| Peserta | Buyer + Seller (2 orang) | Buyer + Seller + Admin (3 orang) |
| Tabel DB | `messages` | `dispute_messages` |
| Endpoint | `/api/chat/[id]/messages` | `/api/disputes/[id]/messages` |
| Konteks | Produk / Pesanan | Dispute / Komplain |
| Role sistem | Tidak ada | BUYER / SELLER / ADMIN |
| System message | Tidak ada | Ada (untuk notifikasi status) |

---

### Schema Database Dispute Chat

```
DisputeMessage {
  id          String
  disputeId   String
  senderId    String
  senderRole  Enum(BUYER, SELLER, ADMIN)
  message     String
  attachments String[]  // array URL foto/dokumen
  isSystemMsg Boolean   // true = pesan otomatis dari sistem
  createdAt   DateTime
  sender: { name, image }
}
```

---

### Alur Lengkap Penyelesaian Komplain

```
FASE 1 — Buyer Ajukan Komplain
  Buyer: POST /api/disputes
  Body: { orderId, reason, description, requestedAction, evidenceUrls }
  → dispute dibuat, status: PENDING_SELLER
  → Seller dapat notifikasi

FASE 2 — Seller Merespons
  Seller: POST /api/seller/disputes/[id]/respond
  Body: { response, agreed: true/false }
  → Jika agreed → bisa langsung proses
  → Jika tidak agreed → status: SELLER_RESPONDED

FASE 3 — Mediasi Admin (jika tidak sepakat)
  Buyer/Seller: POST /api/disputes/[id]/escalate
  → Admin bergabung di chat room
  → Status: IN_MEDIATION

FASE 4 — Chat Mediasi Berlangsung
  Semua pihak: POST /api/disputes/[id]/messages { message }
  → Komunikasi di chat room
  → Admin bisa kirim pesan, buyer & seller bisa balas

FASE 5 — Penyelesaian
  a. Buyer: Selesaikan pesanan (lanjutkan tanpa refund)
  b. Buyer retur barang: submit resi → seller konfirmasi → Admin proses refund
  c. Admin: Konfirmasi transfer manual selesai
```

---

### API Chat Room Komplain

#### GET /api/disputes/[id] — Detail dispute + semua pesan chat

```http
GET /api/disputes/[id]
Authorization: Bearer <token>

Response 200:
{
  "id": "dispute-id",
  "disputeNumber": "DSP-20260727-00001",
  "status": "IN_MEDIATION",
  "reason": "NOT_AS_DESCRIBED",
  "description": "Warna tidak sesuai foto",
  "requestedAction": "REFUND_FULL",
  "resolution": null,
  "refundAmount": null,

  "returnTrackingNumber": null,
  "returnCourier": null,
  "returnShippedAt": null,
  "returnReceivedAt": null,

  "order": {
    "orderNumber": "ORD-xxx",
    "total": 450000,
    "status": "PROCESSING",
    "items": [...]
  },
  "buyer": { "id": "...", "name": "Angga", "image": null },
  "seller": { "id": "...", "name": "Toko Batu", "image": null },
  "assignedAdmin": { "id": "...", "name": "Admin MajaCraft", "image": null },

  "messages": [
    {
      "id": "msg-id",
      "senderRole": "BUYER",
      "isSystemMsg": false,
      "message": "Warna sangat beda!",
      "createdAt": "...",
      "sender": { "name": "Angga", "image": null }
    },
    {
      "id": "sys-msg-id",
      "senderRole": "ADMIN",
      "isSystemMsg": true,
      "message": "Komplain telah diselesaikan. Kesepakatan di ruang mediasi",
      "createdAt": "..."
    }
  ],

  "timeline": [
    { "id": "...", "action": "created", "description": "Komplain diajukan oleh pembeli", "createdAt": "..." },
    { "id": "...", "action": "escalated", "description": "Komplain dieskalasi ke mediasi admin", "createdAt": "..." }
  ]
}
```

---

#### POST /api/disputes/[id]/messages — Kirim pesan di chat room

```http
POST /api/disputes/[id]/messages
Authorization: Bearer <token>
Content-Type: application/json

{ "message": "Isi pesan mediasi" }

Response 201:
{
  "id": "new-msg-id",
  "disputeId": "dispute-id",
  "senderId": "user-id",
  "senderRole": "BUYER",
  "message": "Isi pesan mediasi",
  "isSystemMsg": false,
  "createdAt": "...",
  "sender": { "name": "Angga", "image": null }
}
```

> Hanya buyer, seller, dan admin yang di-assign bisa mengirim pesan.

---

#### POST /api/disputes — Buat komplain baru

```http
POST /api/disputes
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderId": "order-id",
  "reason": "NOT_AS_DESCRIBED",
  "description": "Warna tidak sesuai dengan foto yang ditampilkan.",
  "requestedAction": "REFUND_FULL",
  "evidenceUrls": ["/uploads/evidence/foto1.jpg"]
}

Response 201:
{
  "data": {
    "disputeNumber": "DSP-20260727-00001",
    "dispute": { "id": "dispute-id", ... }
  }
}
```

**Pilihan `reason`:**

```
NOT_AS_DESCRIBED   → Tidak sesuai deskripsi
DAMAGED            → Rusak/cacat
INCOMPLETE         → Tidak lengkap
NOT_RECEIVED       → Tidak diterima (retur tidak diperlukan)
WRONG_ITEM         → Barang salah
FAKE_PRODUCT       → Produk palsu
OTHER              → Lainnya
```

**Pilihan `requestedAction`:**

```
REFUND_FULL      → Refund penuh
REFUND_PARTIAL   → Refund sebagian
REPLACEMENT      → Ganti barang
RETURN_REFUND    → Retur + refund (wajib retur barang)
REPAIR           → Perbaikan
```

---

#### POST /api/disputes/[id]/escalate — Eskalasi ke admin

```http
POST /api/disputes/[id]/escalate
Authorization: Bearer <token>
Content-Type: application/json

{ "reason": "Tidak sepakat dengan penjual" }

Response 200: { "success": true }
```

---

#### PATCH /api/disputes/[id] — Aksi retur & konfirmasi

**Submit resi retur (BUYER):**

```http
PATCH /api/disputes/[id]
Content-Type: application/json

{
  "action": "submit_return_tracking",
  "courier": "JNE",
  "trackingNumber": "JNE123456789",
  "shippingPayer": "BUYER"
}
```

**Konfirmasi barang diterima (SELLER/ADMIN):**

```http
PATCH /api/disputes/[id]
Content-Type: application/json

{ "action": "confirm_return_received" }
```

---

#### POST /api/disputes/[id]/cancel — Batalkan komplain

```http
POST /api/disputes/[id]/cancel
Authorization: Bearer <token>
Content-Type: application/json

{ "reason": "Alasan pembatalan" }
```

---

### Status Dispute & Transisi

```
PENDING_SELLER
  → Menunggu respons seller
  → Buyer bisa: chat, batalkan
  → Seller bisa: respond (setuju/tidak setuju)

SELLER_RESPONDED
  → Seller sudah merespons, tidak sepakat
  → Buyer/Seller bisa: eskalasi ke admin
  → Chat sudah bisa berjalan

IN_MEDIATION
  → Admin bergabung, semua bisa chat
  → Buyer bisa: submit resi (jika perlu retur)
  → Seller bisa: konfirmasi terima retur
  → Admin bisa: proses refund (setelah retur diterima)

REFUND_PENDING
  → Proses refund sedang berjalan
  → Buyer sudah submit resi
  → Menunggu konfirmasi seller/admin

RESOLVED
  → Selesai (dengan resolusi tertentu)

CLOSED / CANCELLED
  → Ditutup/dibatalkan
```

---

### Role & Tampilan Pesan

```
Buyer  → pesan bubble kanan (amber/gold)
Seller → pesan bubble kiri (stone/gray)
Admin  → pesan bubble kiri dengan label "• Mediator" (violet/purple)
System → pesan terpusat (chip/badge biru langit)
```

---

### Tombol Aksi di Chat Room

Tampilkan tombol berdasarkan kondisi:

| Kondisi | User | Tombol |
| --------- | ------ | -------- |
| `status = SELLER_RESPONDED`, tidak setuju | Buyer/Seller | "Eskalasi ke Admin" |
| Perlu retur, belum ada resi | Buyer | Form input resi + kurir |
| Ada resi, belum konfirmasi terima | Seller/Admin | "Konfirmasi Barang Retur Diterima" |
| Semua syarat terpenuhi | Admin | "Proses Refund" |
| `status = REFUND_PENDING`, resolusi = REFUND_APPROVED | Admin | "✓ Konfirmasi Transfer Manual Selesai" |
| Selesai pesanan tanpa refund | Buyer | "Selesaikan Pesanan" |

---

### GET /api/seller/disputes — Daftar komplain (sisi seller)

```http
GET /api/seller/disputes
Authorization: Bearer <token> (role SELLER)

Response:
{
  "disputes": [
    {
      "id": "...",
      "disputeNumber": "DSP-...",
      "status": "PENDING_SELLER",
      "reason": "NOT_AS_DESCRIBED",
      "requestedAction": "REFUND_FULL",
      "order": { "orderNumber": "...", "total": 450000 },
      "buyer": { "name": "...", "image": null },
      "_count": { "messages": 3 }
    }
  ]
}
```

---

## BAGIAN 3: NAVIGASI DARI PESANAN KE CHAT

### Dari Detail Pesanan ke Chat Biasa

```dart
// URL untuk chat pesanan
final storeSlug = order.items.first.product.store.slug;
final storeOwner = await getStoreOwner(storeSlug); // GET /api/stores/[slug]/owner
final chat = await createOrGetChat(
  targetUserId: storeOwner.userId,
  orderId: order.id,
);
Navigator.push(ChatScreen(chatId: chat.id));
```

### Dari Detail Pesanan ke Chat Room Komplain

```dart
// Jika pesanan punya dispute aktif
if (order.disputes?.isNotEmpty == true) {
  final dispute = order.disputes!.first;
  Navigator.push(DisputeChatScreen(
    disputeId: dispute.id,
    orderId: order.id,
  ));
}
```

---

## BAGIAN 4: RINGKASAN SEMUA API CHAT

### Chat Biasa (Produk/Pesanan)

| Method | Endpoint | Fungsi |
| -------- | ---------- | -------- |
| GET | `/api/chat` | Inbox semua percakapan |
| POST | `/api/chat` | Buat/temukan chat dengan user |
| GET | `/api/chat/[id]/messages` | Riwayat pesan + tandai dibaca |
| POST | `/api/chat/[id]/messages` | Kirim pesan |

### Chat Room Komplain

| Method | Endpoint | Fungsi |
| -------- | ---------- | -------- |
| GET | `/api/disputes/[id]` | Detail dispute + semua pesan |
| POST | `/api/disputes/[id]/messages` | Kirim pesan di chat room |
| POST | `/api/disputes` | Buat komplain baru |
| POST | `/api/disputes/[id]/escalate` | Eskalasi ke admin |
| POST | `/api/disputes/[id]/cancel` | Batalkan komplain |
| PATCH | `/api/disputes/[id]` | Submit resi / konfirmasi retur |
| GET | `/api/seller/disputes` | Daftar komplain (seller) |
| POST | `/api/seller/disputes/[id]/respond` | Seller respons komplain |

---

## CATATAN PENTING UNTUK FLUTTER

1. **Dua sistem chat terpisah** — jangan gunakan endpoint chat biasa untuk dispute.

2. **Polling untuk real-time** — Tidak ada WebSocket. Implementasi polling setiap 5-10 detik saat chat screen aktif:

   ```dart
   Timer.periodic(Duration(seconds: 5), (_) => fetchMessages());
   ```

3. **Mark as read otomatis** — GET `/api/chat/[id]/messages` langsung menandai semua pesan sebagai dibaca. Panggil setiap kali screen dibuka atau app foreground.

4. **Blocked messages** — Cek field `isBlocked: true`. Tampilkan visual berbeda (misal: teks abu-abu dengan ikon peringatan) bukan teks kontak yang diblokir.

5. **System messages di dispute** — Field `isSystemMsg: true`. Tampilkan sebagai chip/badge di tengah, bukan bubble chat.

6. **Upload bukti komplain** — Upload foto dulu ke `POST /api/upload` (multipart), dapatkan URL, masukkan ke `evidenceUrls` saat buat dispute.

7. **tombol aksi kondisional** — Baca `dispute.status`, `dispute.resolution`, `dispute.returnTrackingNumber`, `dispute.returnReceivedAt` untuk menentukan tombol mana yang ditampilkan (lihat tabel di Bagian 2).
