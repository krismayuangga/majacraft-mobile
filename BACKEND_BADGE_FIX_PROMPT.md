# Backend Fix: Badge Unread Count (Chat & Notifikasi)

## Masalah

Aplikasi Flutter MajaCraft menampilkan **badge merah** di ikon Chat dan ikon Notifikasi pada AppBar.
Badge ini menunjukkan jumlah pesan/notifikasi yang belum dibaca. Saat ini badge **tidak muncul**
karena backend belum mengembalikan data yang sesuai dengan format yang diharapkan Flutter.

---

## 1. FIX: `GET /api/chat` — Tambahkan `unreadCount` per Percakapan

### Yang Dibutuhkan Flutter

Flutter memanggil `GET /api/chat` dan mengharapkan response array berisi objek percakapan.
**Setiap item HARUS menyertakan field `unreadCount`** (integer) yang berisi jumlah pesan
yang belum dibaca oleh user yang sedang login.

### Format Response yang Diharapkan

```json
[
  {
    "id": "chat-id-123",
    "orderId": null,
    "productId": "product-abc",
    "productName": "Patung Ganesha",
    "product": {
      "id": "product-abc",
      "name": "Patung Ganesha",
      "slug": "patung-ganesha",
      "price": 450000,
      "image": "/uploads/products/xxx.jpg"
    },
    "otherUser": {
      "id": "user-seller-id",
      "name": "Nama Penjual",
      "image": "/uploads/avatars/yyy.jpg"
    },
    "lastMessage": {
      "id": "msg-latest-id",
      "chatId": "chat-id-123",
      "senderId": "user-seller-id",
      "content": "Isi pesan terakhir",
      "isBlocked": false,
      "readAt": null,
      "createdAt": "2026-07-27T10:00:00Z"
    },
    "unreadCount": 3,
    "createdAt": "2026-07-20T08:00:00Z"
  }
]
```

### Cara Menghitung `unreadCount`

`unreadCount` untuk suatu percakapan = **jumlah Message di mana**:
- `chatId = chat.id`
- `senderId != currentUserId` (bukan pesan yang dikirim user sendiri)
- `readAt IS NULL` (belum dibaca)

### Contoh Query Prisma

```typescript
// Dalam GET /api/chat handler
const currentUserId = session.user.id; // dari JWT/session

const chats = await prisma.chat.findMany({
  where: {
    participants: {
      some: { userId: currentUserId }
    }
  },
  include: {
    participants: {
      include: { user: true }
    },
    messages: {
      orderBy: { createdAt: 'desc' },
      take: 1, // hanya lastMessage
    },
    _count: false, // tidak pakai ini
  },
  orderBy: { updatedAt: 'desc' }
});

// Hitung unreadCount secara manual atau dengan query terpisah
const chatsWithUnread = await Promise.all(
  chats.map(async (chat) => {
    const unreadCount = await prisma.message.count({
      where: {
        chatId: chat.id,
        senderId: { not: currentUserId },
        readAt: null,
      },
    });

    const otherParticipant = chat.participants.find(
      (p) => p.userId !== currentUserId
    );

    return {
      id: chat.id,
      orderId: chat.orderId ?? null,
      productId: chat.productId ?? null,
      productName: chat.product?.name ?? '',
      product: chat.product
        ? {
            id: chat.product.id,
            name: chat.product.name,
            slug: chat.product.slug,
            price: chat.product.price,
            image: chat.product.images?.[0]?.url ?? chat.product.image ?? '',
          }
        : null,
      otherUser: otherParticipant
        ? {
            id: otherParticipant.user.id,
            name: otherParticipant.user.name,
            image: otherParticipant.user.image ?? null,
          }
        : null,
      lastMessage: chat.messages[0]
        ? {
            id: chat.messages[0].id,
            chatId: chat.id,
            senderId: chat.messages[0].senderId,
            content: chat.messages[0].content,
            isBlocked: chat.messages[0].isBlocked,
            readAt: chat.messages[0].readAt?.toISOString() ?? null,
            createdAt: chat.messages[0].createdAt.toISOString(),
          }
        : null,
      unreadCount,
      createdAt: chat.createdAt.toISOString(),
    };
  })
);

return NextResponse.json(chatsWithUnread);
```

### Alternatif: Menggunakan Prisma `_count` dengan Filter (Prisma 5+)

```typescript
const chats = await prisma.chat.findMany({
  where: {
    participants: { some: { userId: currentUserId } }
  },
  include: {
    // ...
    _count: {
      select: {
        messages: {
          where: {
            senderId: { not: currentUserId },
            readAt: null,
          }
        }
      }
    }
  }
});

// Akses: chat._count.messages → ini adalah unreadCount
```

---

## 2. FIX: `GET /api/notifications` — Format Field yang Benar

### Yang Dibutuhkan Flutter

Flutter memanggil `GET /api/notifications` dan mem-parse setiap item dengan field berikut:

| Field yang Dibutuhkan Flutter | Tipe | Keterangan |
|-------------------------------|------|------------|
| `id` | `String` | ID notifikasi |
| `userId` | `String` | ID user pemilik |
| `title` | `String` | Judul notifikasi |
| `body` | `String` | **WAJIB: field ini harus `body`, bukan `message`** |
| `type` | `String` | Lihat tipe di bawah |
| `isRead` | `Boolean` | **WAJIB: field ini harus `isRead`, bukan `read`** |
| `data` | `Object?` | Metadata tambahan (opsional, bisa null) |
| `createdAt` | `String` | ISO 8601 datetime |

### Tipe Notifikasi yang Valid

Flutter hanya mengenali tipe-tipe berikut (selain itu fallback ke `system`):
```
new_order
order_status
product_moderated
product_rejected
dispute_created
dispute_resolved
new_chat
system
```

### Format Response yang Diharapkan

```json
[
  {
    "id": "notif-id-123",
    "userId": "user-id",
    "title": "Pesanan Baru",
    "body": "Pesanan #ORD-001 telah dibuat",
    "type": "new_order",
    "isRead": false,
    "data": { "orderId": "order-id-abc" },
    "createdAt": "2026-07-27T10:00:00Z"
  }
]
```

**PERHATIAN:**
- Field HARUS `body` (bukan `message`, bukan `description`)
- Field HARUS `isRead` (bukan `read`, bukan `is_read`)
- Jika database menyimpan dengan nama berbeda, lakukan mapping di response handler

### Contoh Mapping di Next.js Handler

```typescript
// GET /api/notifications
const notifications = await prisma.notification.findMany({
  where: { userId: currentUserId },
  orderBy: { createdAt: 'desc' },
  take: 50,
});

const mapped = notifications.map((n) => ({
  id: n.id,
  userId: n.userId,
  title: n.title,
  body: n.body ?? n.message ?? n.content ?? '', // pastikan field ini ada
  type: n.type,
  isRead: n.isRead ?? n.read ?? false,           // pastikan field ini boolean
  data: n.data ?? null,
  createdAt: n.createdAt.toISOString(),
}));

return NextResponse.json(mapped);
// Atau: return NextResponse.json({ success: true, data: mapped });
```

---

## 3. FIX: `PATCH /api/notifications/[id]` — Mark as Read

Flutter memanggil `PATCH /api/notifications/{notificationId}` untuk menandai notifikasi sebagai sudah dibaca.

### Yang Dibutuhkan

```typescript
// PATCH /api/notifications/[id]
export async function PATCH(req: Request, { params }) {
  const { id } = params;
  // Verifikasi bahwa notifikasi milik user yang sedang login
  
  await prisma.notification.update({
    where: { id },
    data: { isRead: true }, // atau field yang sesuai di schema
  });

  return NextResponse.json({ success: true });
}
```

---

## 4. Verifikasi: Endpoint `GET /api/chat/[id]/messages` — Auto Mark as Read

Saat Flutter membuka chat room dan memanggil `GET /api/chat/{chatId}/messages`,
backend **harus otomatis menandai semua pesan sebagai sudah dibaca** (`readAt = now()`).
Ini yang menyebabkan `unreadCount` berkurang saat user membuka percakapan.

```typescript
// GET /api/chat/[id]/messages
// Setelah mengambil messages, tandai sebagai dibaca:

await prisma.message.updateMany({
  where: {
    chatId: chatId,
    senderId: { not: currentUserId },
    readAt: null,
  },
  data: {
    readAt: new Date(),
  },
});
```

---

## Checklist Fix Backend

- [ ] `GET /api/chat` — setiap item dalam array memiliki field `unreadCount` (integer, ≥ 0)
- [ ] `unreadCount` dihitung dari pesan yang `senderId != currentUser` DAN `readAt IS NULL`
- [ ] `GET /api/notifications` — setiap item memiliki field `body` (string) dan `isRead` (boolean)
- [ ] `PATCH /api/notifications/[id]` — endpoint ini ada dan bekerja
- [ ] `GET /api/chat/[id]/messages` — otomatis set `readAt = now()` saat dibuka

---

## Catatan Tambahan

- Flutter polling chat unread count setiap **10 detik** — pastikan endpoint efisien
- Response format bisa berupa plain array `[...]` ATAU `{ success: true, data: [...] }`
  — Flutter app sudah handle keduanya
- Jika menggunakan `{ success: true, data: [...] }`, pastikan `success` adalah `true`
