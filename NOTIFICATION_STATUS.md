# Status Fitur Notifikasi - Majacraft Mobile

## ✅ Yang Sudah Aktif (In-App Notifications)

### 1. UI & Frontend
- ✅ **Notification List Screen** - Tampilan daftar notifikasi dengan filter
- ✅ **Badge Counter** - Angka notifikasi belum dibaca di bell icon
- ✅ **Pull to Refresh** - Swipe down untuk reload notifikasi
- ✅ **Empty State** - Tampilan ketika belum ada notifikasi
- ✅ **Mark as Read** - Tap notifikasi untuk tandai sudah dibaca
- ✅ **Mark All as Read** - Button untuk tandai semua sebagai dibaca
- ✅ **Filter Tab** - "Semua" dan "Belum Dibaca"
- ✅ **Timeago** - Format waktu Indonesia ("2 jam yang lalu")
- ✅ **Navigation** - Dari bell icon dan menu profile

### 2. API Integration
- ✅ **GET /api/notifications** - Ambil daftar notifikasi (TESTED ✓)
- ✅ **PATCH /api/notifications/:id** - Tandai notifikasi sebagai dibaca
- ✅ **Response Format** - `{success: true, data: {notifications: [], unreadCount: 0}}`
- ✅ **Authentication** - JWT token di Authorization header

### 3. Notification Types
- ✅ ORDER - Notifikasi pesanan (biru)
- ✅ PRODUCT - Notifikasi produk (hijau)
- ✅ REVIEW - Notifikasi review (kuning)
- ✅ SYSTEM - Notifikasi sistem (abu-abu)

### 4. Data Model
```dart
NotificationModel {
  String id;
  String userId;
  String title;
  String message;
  NotificationType type;
  bool read;
  Map<String, dynamic>? data; // Extra data (orderId, productId, dll)
  DateTime createdAt;
}
```

---

## ❌ Yang Belum Ada (Needs Backend & Push Notifications)

### 1. Push Notifications (FCM)
- ❌ **Firebase Cloud Messaging** - Belum setup FCM
- ❌ **Background Notifications** - Notif saat app closed/background
- ❌ **Notification Payload** - Deep link ke order/product detail
- ❌ **Device Token Registration** - Simpan FCM token ke backend
- ❌ **Notification Sounds** - Sound effect saat notif masuk

### 2. Backend Notification Creation
- ❌ **Order Status Change** - Otomatis create notif saat status order berubah
  - Contoh: "Pesanan #123 telah dibayar"
  - Contoh: "Pesanan #123 sedang dikirim"
  - Contoh: "Pesanan #123 telah sampai"

- ❌ **Product Moderation** - Notif untuk seller saat produk disetujui/ditolak
  - Contoh: "Produk 'Kain Batik' telah disetujui"
  - Contoh: "Produk 'Vas Keramik' ditolak: Foto tidak jelas"

- ❌ **New Review** - Notif untuk seller saat dapat review baru
  - Contoh: "Anda mendapat review baru untuk produk 'Kain Batik'"

- ❌ **System Announcements** - Notif dari admin untuk semua user
  - Contoh: "Selamat datang di Majacraft!"
  - Contoh: "Promo Flash Sale 50% hingga 31 Juli!"

- ❌ **Low Stock Alert** - Notif untuk seller saat stok menipis
  - Contoh: "Stok produk 'Kain Batik' tinggal 2 pcs"

---

## 🧪 Cara Test Notifikasi (Current)

### Test 1: Empty State
**Status**: ✅ BISA DITEST SEKARANG
1. Login sebagai testmobile@majacraft.id
2. Tap bell icon di home screen
3. Lihat empty state: "Belum ada notifikasi"
4. Badge counter harus kosong (tidak tampil)

### Test 2: Load Notifications
**Status**: ✅ BISA DITEST SEKARANG (tapi data kosong)
1. Tap bell icon
2. Pull to refresh
3. Check console log: `[NotificationService] Found 0 notifications`
4. API call harus success 200

### Test 3: Mark as Read
**Status**: ⏳ MENUNGGU DATA (butuh backend create notif dulu)
1. Butuh notifikasi real dari backend
2. Tap pada notifikasi card
3. Notifikasi harus berubah dari bold ke normal
4. Badge counter harus berkurang

### Test 4: Filter Tab
**Status**: ⏳ MENUNGGU DATA (butuh backend create notif dulu)
1. Butuh notifikasi read dan unread
2. Tap "Belum Dibaca"
3. Hanya tampil notifikasi unread
4. Count badge harus sesuai

---

## 🎯 Next Steps - Apa yang Perlu Dilakukan Backend

### Priority 1: Create Test Notifications (Backend)
Backend perlu implement endpoint atau fungsi untuk create notifikasi manual:

```typescript
// Backend API endpoint untuk create test notification
POST /api/notifications/test
{
  "userId": "cmrwgcfvg0000krad2q3pqil8",
  "title": "Selamat Datang!",
  "message": "Terima kasih telah bergabung dengan Majacraft",
  "type": "SYSTEM"
}
```

Atau buat langsung di database:
```sql
INSERT INTO Notification (id, userId, title, message, type, read, createdAt)
VALUES (
  'notif-test-001',
  'cmrwgcfvg0000krad2q3pqil8',
  'Selamat Datang!',
  'Terima kasih telah bergabung dengan Majacraft',
  'SYSTEM',
  false,
  NOW()
);
```

### Priority 2: Order Status Notifications
Saat order status berubah di backend, otomatis create notification:

```typescript
// Backend service example
async function updateOrderStatus(orderId: string, newStatus: string) {
  // Update order
  await db.order.update({
    where: { id: orderId },
    data: { status: newStatus }
  });
  
  // Get order details
  const order = await db.order.findUnique({
    where: { id: orderId },
    include: { buyer: true, seller: true }
  });
  
  // Create notification for buyer
  await db.notification.create({
    data: {
      userId: order.buyerId,
      title: `Pesanan #${order.orderNumber}`,
      message: getOrderStatusMessage(newStatus),
      type: 'ORDER',
      data: JSON.stringify({ orderId, status: newStatus })
    }
  });
  
  // Create notification for seller
  await db.notification.create({
    data: {
      userId: order.sellerId,
      title: `Pesanan #${order.orderNumber}`,
      message: getOrderStatusMessage(newStatus),
      type: 'ORDER',
      data: JSON.stringify({ orderId, status: newStatus })
    }
  });
}
```

### Priority 3: Push Notifications (Mobile + Backend)
Setup Firebase Cloud Messaging:

**Mobile Side:**
1. Install `firebase_messaging` package
2. Setup Firebase project di console
3. Add google-services.json (Android) dan GoogleService-Info.plist (iOS)
4. Request notification permission
5. Get FCM token dan kirim ke backend
6. Handle notification tap untuk navigation

**Backend Side:**
1. Install `firebase-admin` npm package
2. Save FCM tokens per user di database
3. Saat create notification, kirim push notification juga:

```typescript
import admin from 'firebase-admin';

async function sendPushNotification(userId: string, title: string, body: string, data?: any) {
  // Get user's FCM tokens
  const tokens = await db.deviceToken.findMany({
    where: { userId }
  });
  
  if (tokens.length === 0) return;
  
  // Send to all user's devices
  await admin.messaging().sendEachForMulticast({
    tokens: tokens.map(t => t.token),
    notification: {
      title,
      body
    },
    data,
    android: {
      priority: 'high'
    },
    apns: {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    }
  });
}
```

---

## 📊 Summary

| Fitur | Status | Keterangan |
|-------|--------|-----------|
| In-App Notification UI | ✅ AKTIF | Tampilan notifikasi sudah jalan |
| Badge Counter | ✅ AKTIF | Angka unread sudah muncul |
| Load dari API | ✅ AKTIF | API call works, data masih kosong |
| Mark as Read | ✅ AKTIF | Fungsi ada, menunggu data |
| Filter Tab | ✅ AKTIF | Fungsi ada, menunggu data |
| **Push Notification** | ❌ BELUM | **Butuh setup FCM** |
| **Backend Create Notif** | ❌ BELUM | **Butuh event handlers** |
| Deep Link Navigation | ❌ BELUM | Butuh router handler |

---

## 🚀 Quick Test Guide

### Untuk Test SEKARANG:
1. ✅ Tap bell icon → Lihat empty state
2. ✅ Pull to refresh → Lihat loading animation
3. ✅ Check console log → API call success 200
4. ✅ Badge counter kosong (tidak tampil)

### Untuk Test NANTI (setelah backend ready):
1. ⏳ Backend create test notification
2. ⏳ Refresh app → Lihat notifikasi muncul
3. ⏳ Badge counter menampilkan jumlah unread
4. ⏳ Tap notifikasi → Berubah jadi read, badge berkurang
5. ⏳ Filter "Belum Dibaca" → Filter works
6. ⏳ "Tandai Semua Dibaca" → Semua jadi read, badge = 0

---

## 💡 Recommendation

**Fase 1: In-App Notifications (SELESAI ✅)**
- UI dan API integration sudah complete
- Tinggal menunggu backend create notifications

**Fase 2: Backend Integration (NEXT 🔴)**
- Backend team implement notification creation
- Order status change → create notification
- Product moderation → create notification
- New review → create notification

**Fase 3: Push Notifications (FUTURE 🔵)**
- Setup FCM di mobile app
- Backend kirim push notification
- Deep link navigation ke detail page

**Kesimpulan**: In-app notification sudah aktif dan berfungsi. Tinggal menunggu backend untuk:
1. Create notifikasi otomatis saat ada event
2. (Optional) Setup push notification untuk real-time alerts
