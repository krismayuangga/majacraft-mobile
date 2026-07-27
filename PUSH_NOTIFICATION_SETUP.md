# Push Notification Setup - MajaCraft Mobile

Panduan lengkap untuk mengaktifkan push notification menggunakan Firebase Cloud Messaging (FCM).

## 📋 Prerequisites

- Firebase Project (create di [Firebase Console](https://console.firebase.google.com))
- Android Studio / Xcode
- Access ke backend codebase untuk integrasi

---

## 🔥 Firebase Project Setup

### 1. Create Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Klik "Add project" atau "Create a project"
3. Nama project: **MajaCraft** (atau sesuai preferensi)
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Register Android App

1. Di Firebase Console, pilih project MajaCraft
2. Klik icon Android untuk add Android app
3. Package name: `com.majacraft.mobile` (sesuaikan dengan `android/app/build.gradle`)
4. App nickname: **MajaCraft Mobile**
5. Debug signing certificate SHA-1 (optional untuk development):
   ```bash
   cd android
   ./gradlew signingReport
   # Copy SHA-1 dari output "Task :app:signingReport"
   ```
6. Click "Register app"
7. **Download `google-services.json`**
8. Place file ke: `android/app/google-services.json`

### 3. Register iOS App

1. Di Firebase Console, klik icon iOS
2. Bundle ID: `com.majacraft.mobile` (sesuaikan dengan Xcode project)
3. App nickname: **MajaCraft Mobile**
4. Click "Register app"
5. **Download `GoogleService-Info.plist`**
6. Open Xcode: `open ios/Runner.xcworkspace`
7. Drag `GoogleService-Info.plist` ke Runner folder (ensure "Copy items if needed" is checked)

---

## 📱 Android Configuration

### 1. Update `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.2'  // Add this
    }
}
```

### 2. Update `android/app/build.gradle`

```gradle
// At the bottom of the file
apply plugin: 'com.google.gms.google-services'  // Add this line
```

### 3. Update `android/app/src/main/AndroidManifest.xml`

Add di dalam `<application>` tag:

```xml
<application>
    <!-- ... existing code ... -->

    <!-- FCM default notification channel -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="majacraft_default" />
    
    <!-- FCM icon -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@mipmap/ic_launcher" />
    
    <!-- FCM color -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_color"
        android:resource="@color/notification_color" />
</application>
```

### 4. Create `android/app/src/main/res/values/colors.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#653611</color>  <!-- MajaCraft brown -->
</resources>
```

---

## 🍎 iOS Configuration

### 1. Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Signing & Capabilities
3. Click "+ Capability"
4. Add **Push Notifications**
5. Add **Background Modes** → Check "Remote notifications"

### 2. Update `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter
import Firebase  // Add this

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()  // Add this
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 3. APNs Authentication Key

1. Go to [Apple Developer](https://developer.apple.com)
2. Certificates, Identifiers & Profiles → Keys
3. Create a new key:
   - Key Name: **MajaCraft Push Notifications**
   - Enable: **Apple Push Notifications service (APNs)**
4. Download `.p8` file
5. Upload di Firebase Console:
   - Project Settings → Cloud Messaging → iOS app configuration
   - Upload APNs Authentication Key
   - Team ID: dari Apple Developer Account
   - Key ID: dari key yang dibuat

---

## 🔧 Flutter App Integration

### 1. Update `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize FCM service
  await FCMService().initialize();
  
  runApp(const MyApp());
}
```

### 2. Update `lib/providers/auth_provider.dart`

Add FCM token registration after successful login:

```dart
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  // ... existing code ...

  Future<void> login(String email, String password) async {
    // ... existing login logic ...
    
    if (_token != null && _user != null) {
      // Register FCM token with backend
      final fcmToken = FCMService().fcmToken;
      if (fcmToken != null) {
        await FCMService().registerTokenWithBackend(fcmToken, _token!);
      }
    }
  }

  Future<void> logout() async {
    // Unregister FCM token before logout
    if (_token != null) {
      await FCMService().unregisterTokenFromBackend(_token!);
    }
    
    // Clear local FCM token
    await FCMService().clearLocalToken();
    
    // ... existing logout logic ...
  }
}
```

---

## 🖥️ Backend Integration

Backend perlu mengimplementasikan endpoints dan logic untuk push notification.

### 1. Required Backend Endpoints

#### POST `/api/user/fcm-token`

Register FCM token dari mobile app.

**Request:**
```json
{
  "fcmToken": "fcm_token_string_from_device"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token registered"
}
```

**Backend Implementation:**
- Save `fcmToken` ke user record di database
- Field: `User.fcmToken` (nullable string)
- Update existing token jika user sudah punya

#### DELETE `/api/user/fcm-token`

Unregister FCM token (saat logout).

**Response:**
```json
{
  "success": true,
  "message": "FCM token unregistered"
}
```

**Backend Implementation:**
- Set `User.fcmToken = null`

### 2. Backend: Send Push Notifications

Install Firebase Admin SDK di backend (Node.js/Next.js):

```bash
npm install firebase-admin
```

**Initialize Firebase Admin (`lib/firebase-admin.ts`):**

```typescript
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export const messaging = admin.messaging();
```

**Environment Variables (`.env.local`):**

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

> Get these from Firebase Console → Project Settings → Service Accounts → Generate new private key

**Send Notification Function (`lib/send-notification.ts`):**

```typescript
import { messaging } from './firebase-admin';

export async function sendPushNotification(
  fcmToken: string,
  notification: {
    title: string;
    body: string;
    type: 'new_order' | 'order_status' | 'new_chat' | 'dispute_update' | 'review_reminder' | 'system';
    data?: Record<string, string>;
  }
) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: notification.type,
        ...notification.data,
      },
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'majacraft_default',
          sound: 'default',
          color: '#653611',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await messaging.send(message);
    console.log('[FCM] Notification sent:', response);
    return response;
  } catch (error) {
    console.error('[FCM] Error sending notification:', error);
    throw error;
  }
}
```

### 3. Backend: Trigger Notifications

Integrate push notifications di berbagai event:

#### A. New Order Notification (Seller)

```typescript
// After order creation
const order = await prisma.order.create({...});

// Send push to seller
const seller = await prisma.user.findUnique({
  where: { id: order.product.storeId },
  select: { fcmToken: true }
});

if (seller?.fcmToken) {
  await sendPushNotification(seller.fcmToken, {
    title: '🎉 Pesanan Baru!',
    body: `${order.buyerName} memesan ${order.productName}`,
    type: 'new_order',
    data: {
      orderId: order.id,
      orderNumber: order.orderNumber,
    },
  });
}
```

#### B. Order Status Update (Buyer)

```typescript
// After order status update
const order = await prisma.order.update({
  where: { id: orderId },
  data: { status: newStatus },
  include: { buyer: { select: { fcmToken: true } } }
});

if (order.buyer.fcmToken) {
  await sendPushNotification(order.buyer.fcmToken, {
    title: 'Update Status Pesanan',
    body: `Pesanan ${order.orderNumber} telah ${getStatusText(newStatus)}`,
    type: 'order_status',
    data: {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: newStatus,
    },
  });
}
```

#### C. New Chat Message

```typescript
// After sending message
const message = await prisma.chatMessage.create({...});

// Get recipient
const chat = await prisma.chat.findUnique({
  where: { id: message.chatId },
  include: {
    buyer: { select: { fcmToken: true, name: true } },
    seller: { select: { fcmToken: true, storeName: true } },
  }
});

// Determine recipient
const isFromBuyer = message.senderId === chat.buyerId;
const recipient = isFromBuyer ? chat.seller : chat.buyer;

if (recipient?.fcmToken) {
  await sendPushNotification(recipient.fcmToken, {
    title: isFromBuyer ? chat.buyer.name : chat.seller.storeName,
    body: message.content,
    type: 'new_chat',
    data: {
      chatId: chat.id,
      productId: chat.productId || '',
    },
  });
}
```

#### D. Dispute Update

```typescript
// After dispute status change
const dispute = await prisma.dispute.update({...});

// Send to both buyer and seller
const [buyer, seller] = await Promise.all([
  prisma.user.findUnique({ where: { id: dispute.buyerId }, select: { fcmToken: true } }),
  prisma.user.findUnique({ where: { id: dispute.sellerId }, select: { fcmToken: true } }),
]);

const notifications = [];
if (buyer?.fcmToken) notifications.push(sendPushNotification(buyer.fcmToken, {...}));
if (seller?.fcmToken) notifications.push(sendPushNotification(seller.fcmToken, {...}));

await Promise.all(notifications);
```

---

## 🧪 Testing

### 1. Test FCM Setup

Run app dan check console logs:

```bash
flutter run
```

Expected output:
```
[FCM] User granted notification permission
[FCM] Token: fXXXXXXXXXXXXX
```

### 2. Test Notification via Firebase Console

1. Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Notification title & text
4. Target: Select your test device (FCM token)
5. Send test notification

### 3. Test from Backend

Create test endpoint:

```typescript
// pages/api/test-notification.ts
export default async function handler(req, res) {
  const { fcmToken } = req.body;
  
  await sendPushNotification(fcmToken, {
    title: 'Test Notification',
    body: 'This is a test from backend',
    type: 'system',
  });
  
  res.json({ success: true });
}
```

Test via curl:

```bash
curl -X POST http://localhost:3000/api/test-notification \
  -H "Content-Type: application/json" \
  -d '{"fcmToken": "YOUR_FCM_TOKEN"}'
```

---

## 📊 Database Schema Changes

Add FCM token field to User table:

```prisma
model User {
  // ... existing fields ...
  fcmToken      String?
  fcmTokenUpdatedAt DateTime?
}
```

Run migration:

```bash
npx prisma migrate dev --name add_fcm_token
```

---

## 🔔 Notification Types & Data Payload

| Type | Title Example | Body Example | Data Payload |
|------|--------------|--------------|--------------|
| `new_order` | 🎉 Pesanan Baru! | John memesan Gentong Antik | `orderId`, `orderNumber` |
| `order_status` | Update Status Pesanan | Pesanan #ORD123 telah dikirim | `orderId`, `orderNumber`, `status` |
| `new_chat` | Store Name / Buyer Name | Pesan dari buyer/seller | `chatId`, `productId` |
| `dispute_update` | Update Komplain | Komplain #DIS123 telah diproses | `disputeId`, `disputeNumber` |
| `review_reminder` | Reminder Ulasan | Berikan ulasan untuk pesanan Anda | `orderId`, `productId` |
| `system` | Pengumuman | Ada update penting dari MajaCraft | - |

---

## 🐛 Troubleshooting

### Android: Notification not showing

1. Check `google-services.json` is in `android/app/`
2. Rebuild: `flutter clean && flutter run`
3. Check logcat: `adb logcat | grep FCM`

### iOS: Notification not showing

1. Check `GoogleService-Info.plist` is in Xcode project
2. Verify APNs key uploaded in Firebase Console
3. Check capabilities: Push Notifications + Background Modes enabled
4. Check device: Settings → Notifications → MajaCraft (allow notifications)

### Token is null

- Check internet connection
- Check Firebase initialization in main.dart
- Check permissions granted

### Background notifications not received

- Check `onBackgroundMessage` handler registered in main.dart
- iOS: Check Background Modes → Remote notifications enabled

---

## 📝 Next Steps

1. ✅ Install dependencies: `flutter pub get`
2. ✅ Setup Firebase project & download config files
3. ✅ Configure Android & iOS projects
4. ✅ Test FCM token generation
5. ⚠️ Backend: Implement FCM endpoints
6. ⚠️ Backend: Integrate notification triggers
7. ⚠️ Test end-to-end notification flow

---

## 🎯 Real-time Chat Badge

Chat unread badge di navbar sudah diimplementasikan dengan polling setiap 10 detik. Dengan push notification, badge akan update otomatis saat ada pesan baru:

1. **Polling** (current): Check unread count every 10s
2. **Push Notification**: Instant update when new message received
3. **Badge Update**: Automatically refresh when notification tapped

---

**Status:** ✅ Mobile app siap, menunggu backend integration untuk full functionality.
