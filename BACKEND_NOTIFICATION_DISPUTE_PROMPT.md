# Backend Fix: Push Notification untuk Room Komplain & Dispute

## Masalah

Saat ada pesan baru di room komplain/dispute (`POST /api/disputes/{id}/messages`),
tidak ada notifikasi yang dikirim ke buyer, seller, maupun admin di aplikasi mobile
maupun web.

---

## Yang Perlu Diimplementasi di Backend

### 1. Endpoint Registrasi FCM Token

Flutter mengirim FCM token setelah login ke:

```http
POST /api/mobile/fcm-token
Authorization: Bearer <token>
Content-Type: application/json

{ "fcmToken": "fcm-token-string-dari-firebase" }

Response 200:
{ "success": true }
```

Simpan FCM token di tabel `User` atau tabel terpisah `UserFCMToken`.

```prisma
// Tambah di model User (atau buat model baru)
model User {
  // ... existing fields
  fcmToken  String?   // FCM token untuk push notification
  fcmTokenUpdatedAt DateTime?
}
```

**Atau buat model terpisah (lebih baik untuk multi-device):**

```prisma
model UserDevice {
  id        String   @id @default(cuid())
  userId    String
  fcmToken  String   @unique
  platform  String?  // "android" | "ios"
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  user      User     @relation(fields: [userId], references: [id])
}
```

---

### 2. Kirim FCM Notification saat Pesan Dispute Baru

Di handler `POST /api/disputes/{id}/messages`:

```typescript
// Setelah menyimpan pesan ke database:
await sendDisputeMessageNotification(dispute, newMessage, senderUserId);
```

```typescript
async function sendDisputeMessageNotification(
  dispute: Dispute,
  message: DisputeMessage,
  senderUserId: string
) {
  // Kumpulkan semua userId yang perlu dinotifikasi (kecuali pengirim)
  const notifyUserIds = [
    dispute.buyerId,
    dispute.sellerId,
    dispute.assignedAdminId, // null kalau belum ada admin
  ].filter((id) => id && id !== senderUserId) as string[];

  for (const userId of notifyUserIds) {
    // 1. Buat record Notification di database
    await prisma.notification.create({
      data: {
        userId,
        title: 'Pesan Baru di Komplain',
        body: `${message.sender.name}: ${message.message.substring(0, 80)}`,
        type: 'dispute_update',
        isRead: false,
        data: {
          disputeId: dispute.id,
          disputeNumber: dispute.disputeNumber,
          messageId: message.id,
        },
      },
    });

    // 2. Kirim push notification via FCM
    const fcmToken = await getFCMToken(userId);
    if (fcmToken) {
      await sendFCMNotification(fcmToken, {
        title: `Komplain #${dispute.disputeNumber}`,
        body: `${message.sender.name}: ${message.message.substring(0, 100)}`,
        data: {
          type: 'dispute_update',
          disputeId: dispute.id,
          disputeNumber: dispute.disputeNumber,
        },
      });
    }
  }
}
```

---

### 3. Kirim Notifikasi saat Dispute Dibuat

Di handler `POST /api/disputes`:

```typescript
// Setelah dispute berhasil dibuat, notifikasi seller:
await prisma.notification.create({
  data: {
    userId: dispute.sellerId,
    title: 'Komplain Baru dari Pembeli',
    body: `Pembeli mengajukan komplain untuk pesanan ${order.orderNumber}. Alasan: ${reason}.`,
    type: 'dispute_created',
    isRead: false,
    data: {
      disputeId: dispute.id,
      orderId: dispute.orderId,
    },
  },
});

// Kirim FCM ke seller
const sellerFCMToken = await getFCMToken(dispute.sellerId);
if (sellerFCMToken) {
  await sendFCMNotification(sellerFCMToken, {
    title: 'Komplain Baru dari Pembeli',
    body: `Pesanan ${order.orderNumber} memiliki komplain baru.`,
    data: {
      type: 'dispute_created',
      disputeId: dispute.id,
    },
  });
}
```

---

### 4. Helper Functions untuk FCM

```typescript
import * as admin from 'firebase-admin';

// Inisialisasi Firebase Admin SDK (sekali di startup)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

async function getFCMToken(userId: string): Promise<string | null> {
  // Ambil dari field fcmToken di User, atau dari tabel UserDevice
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });
  return user?.fcmToken ?? null;
}

async function sendFCMNotification(
  fcmToken: string,
  payload: { title: string; body: string; data?: Record<string, string> }
) {
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default' } },
      },
    });
    console.log('[FCM] Notification sent to token:', fcmToken.substring(0, 20) + '...');
  } catch (error) {
    console.error('[FCM] Failed to send notification:', error);
    // Jangan throw — notifikasi gagal tidak boleh block proses utama
  }
}
```

---

### 5. Environment Variables yang Dibutuhkan

Tambahkan di `.env`:

```env
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

File service account JSON bisa didownload dari Firebase Console → Project Settings → Service Accounts → Generate New Private Key.

---

## Checklist Backend

- [ ] Tambah field `fcmToken` di `User` model (atau tabel `UserDevice`)
- [ ] Buat endpoint `POST /api/mobile/fcm-token` untuk menyimpan FCM token
- [ ] Inisialisasi Firebase Admin SDK di server
- [ ] Di `POST /api/disputes` — kirim notifikasi ke seller saat dispute dibuat
- [ ] Di `POST /api/disputes/{id}/messages` — kirim notifikasi ke semua peserta (kecuali pengirim)
- [ ] Notification record dibuat di database (agar badge di-app terbaca)
- [ ] Handle expired FCM token (hapus token invalid dari database)

---

## Catatan Flutter (sudah diimplementasi)

- Firebase.initializeApp() sekarang dipanggil di `main.dart`
- FCM token dikirim ke `/api/mobile/fcm-token` setelah login/Google sign-in
- NotificationType `dispute_update` sudah ditambahkan
- Saat notifikasi di-tap, app akan navigate ke dispute chat (butuh NavigatorKey global)
