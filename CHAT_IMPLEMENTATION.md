# Implementasi Fitur Chat - Majacraft Mobile

## 📋 Ringkasan Implementasi

Implementasi lengkap sistem chat untuk aplikasi Majacraft Mobile, mencakup:
- ✅ Chat biasa (buyer-seller)
- ✅ Dispute/Komplain dengan mediasi admin
- ✅ Polling untuk real-time updates
- ✅ Unread message badges
- ✅ Contact blocking (phone, WA, Telegram)
- ✅ Role-based UI colors

---

## 📁 File Yang Dibuat

### 1. Models
- **`lib/models/chat.dart`** - Models untuk chat biasa
  - `ChatUser` - Data user dalam chat
  - `ChatProduct` - Info produk terkait chat
  - `Message` - Model pesan dengan isRead checker
  - `Chat` - Model chat dengan unread counter

- **`lib/models/dispute.dart`** - Models untuk dispute/komplain
  - `DisputeStatus`, `DisputeReason`, `DisputeAction`, `SenderRole` - Enums dengan display names
  - `DisputeUser`, `DisputeMessage`, `DisputeTimeline`, `DisputeOrder` - Supporting models
  - `Dispute` - Full dispute model dengan helper methods

### 2. Services
- **`lib/services/chat_service.dart`** - API service untuk chat biasa
  - `getChatInbox()` - Ambil inbox
  - `createOrGetChat()` - Buat/cari chat
  - `getChatMessages()` - Ambil pesan (auto mark as read)
  - `sendMessage()` - Kirim pesan (dengan blocking detection)
  - `getStoreOwner()` - Ambil seller info
  - `getTotalUnreadCount()` - Hitung total unread

- **`lib/services/dispute_service.dart`** - API service untuk dispute
  - `getDispute()` - Detail dispute + messages
  - `createDispute()` - Buat komplain baru
  - `sendDisputeMessage()` - Kirim pesan di dispute chat
  - `escalateDispute()` - Eskalasi ke admin
  - `cancelDispute()` - Batalkan komplain
  - `submitReturnTracking()` - Submit resi retur (buyer)
  - `confirmReturnReceived()` - Konfirmasi terima barang (seller)
  - `getSellerDisputes()` - List komplain seller
  - `respondToDispute()` - Seller respond komplain

### 3. Screens
- **`lib/screens/chat_list_screen.dart`** - Inbox semua chat
  - List chat dengan last message
  - Unread count badges
  - Pull-to-refresh
  - Empty state
  - Navigation ke ChatScreen

- **`lib/screens/chat_screen.dart`** - Chat room biasa (buyer-seller)
  - Polling setiap 5 detik
  - Message bubbles (amber untuk buyer, gray untuk seller)
  - Blocked messages dengan border merah
  - Product info di header
  - Auto scroll to bottom
  - Send message dengan loading state

- **`lib/screens/dispute_chat_screen.dart`** - Chat room dispute dengan admin
  - Polling setiap 10 detik
  - 3-way chat (buyer/seller/admin)
  - Role-based colors: amber (buyer), blue (seller), green (admin)
  - System messages
  - Order info header dengan status badge
  - Conditional action buttons:
    - Submit resi retur (buyer)
    - Konfirmasi terima barang (seller)
    - Eskalasi ke admin
    - Batalkan komplain
  - Timeline tracking

### 4. Integration Updates
- **`lib/screens/product_detail_screen.dart`**
  - ✅ Tombol "Chat" di bottom bar
  - ✅ Integration dengan ChatService
  - ✅ Navigate ke ChatScreen dengan product context

- **`lib/screens/store_detail_screen.dart`**
  - ✅ FloatingActionButton "Chat Seniman"
  - ✅ Integration complete
  - ✅ Navigate ke ChatScreen tanpa product context

- **`lib/screens/studio/order_detail_screen.dart`**
  - ✅ Tombol "Chat Pembeli" (seller side)
  - ⚠️ **TODO**: Backend perlu expose buyer ID di order API

- **`lib/widgets/main_screen.dart`**
  - ✅ Chat tab di bottom navigation (index 4)
  - ✅ Unread count badge dengan polling setiap 10 detik
  - ✅ Red badge dengan counter

---

## 🔌 API Endpoints

### Chat Biasa
```
GET  /api/chat                    - Inbox
POST /api/chat                    - Create/get chat
GET  /api/chat/[id]/messages      - Get messages (auto mark as read)
POST /api/chat/[id]/messages      - Send message
GET  /api/stores/[slug]/owner     - Get seller info
```

### Dispute
```
GET   /api/disputes/[id]                      - Detail + messages
POST  /api/disputes                           - Create dispute
POST  /api/disputes/[id]/messages             - Send message
POST  /api/disputes/[id]/escalate             - Escalate
POST  /api/disputes/[id]/cancel               - Cancel
PATCH /api/disputes/[id]                      - Submit resi / confirm return
GET   /api/seller/disputes                    - Seller disputes
POST  /api/seller/disputes/[id]/respond       - Seller respond
```

---

## ⚙️ Konfigurasi

### Polling Intervals
- Chat inbox unread count: **10 detik**
- Chat room messages: **5 detik**
- Dispute room messages: **10 detik**

### Role Colors
- **Buyer**: Amber (#FFA726)
- **Seller**: Blue (#42A5F5)
- **Admin**: Green (#66BB6A)
- **System Messages**: Gray background

### Blocked Messages
Pesan otomatis diblokir jika mengandung:
- Nomor HP
- Nomor WhatsApp
- Username Telegram
- Email (optional blocking)

---

## 🧪 Testing Checklist

### Chat Biasa
- [ ] Open chat dari Product Detail page
- [ ] Open chat dari Store Detail page
- [ ] Send message berhasil
- [ ] Blocked message detection bekerja
- [ ] Messages auto mark as read
- [ ] Polling updates messages
- [ ] Unread badge di navbar update
- [ ] Empty state tampil jika belum ada chat

### Dispute Chat
- [ ] Create dispute dari Order Detail
- [ ] 3-way chat bekerja (buyer, seller, admin)
- [ ] Role colors correct
- [ ] System messages tampil
- [ ] Submit resi button muncul untuk buyer (status AWAITING_RETURN_SHIPMENT)
- [ ] Confirm return button muncul untuk seller (status RETURN_IN_TRANSIT)
- [ ] Escalate button bekerja
- [ ] Cancel dispute bekerja
- [ ] Status badge update
- [ ] Timeline tracking

### Navigation
- [ ] Chat tab di navbar accessible
- [ ] Unread badge tampil dan update
- [ ] Back navigation bekerja dari semua screens
- [ ] Deep linking dari notifications (future)

---

## 🐛 Known Issues & TODOs

### Backend Requirements
1. **Order API Enhancement** (`/api/studio/orders/[id]`)
   - ⚠️ Perlu expose `buyerId` dan `buyerName` untuk chat seller-buyer
   - Current: Hanya ada `recipientName` dan `recipientPhone`
   - File: `lib/screens/studio/order_detail_screen.dart:134`

2. **Buyer-Side Order Detail**
   - Belum ada screen untuk buyer order detail
   - Perlu buat screen dengan tombol "Chat Penjual" dan "Buat Komplain"

### Mobile Enhancements
1. **Push Notifications**
   - Integrate dengan Firebase Cloud Messaging
   - Handle notification tap → deep link ke chat/dispute screen

2. **Image Attachments** (Future)
   - Upload foto di dispute evidence
   - Send image dalam chat biasa

3. **Chat Archive**
   - Archive/mute chat
   - Delete chat history

---

## 📦 Dependencies

Semua dependencies sudah ada di `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  http: ^1.2.0
  timeago: ^3.6.0  # For relative timestamps
```

---

## 🚀 Deployment Steps

1. **Verify Backend APIs**
   ```bash
   # Test endpoints
   curl https://majacraft.id/api/chat -H "Authorization: Bearer <token>"
   curl https://majacraft.id/api/disputes/[id] -H "Authorization: Bearer <token>"
   ```

2. **Build & Test**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Test Scenarios**
   - Login as BUYER → test chat dengan seller
   - Login as SELLER → test respond chat, handle disputes
   - Test blocked message detection
   - Test polling updates
   - Test navigation flow

4. **Release Build**
   ```bash
   flutter build apk --release        # Android
   flutter build ios --release        # iOS
   ```

---

## 📞 Support

Untuk pertanyaan atau bug reports:
- Check console logs: `[ChatService]`, `[DisputeService]`, `[ChatScreen]`, etc.
- Backend logs: Check Next.js server logs
- Cek network requests di Flutter DevTools

---

## ✅ Status Implementasi

**Phase 1 - Foundation**: ✅ Complete
- Models
- Services (ChatService, DisputeService)

**Phase 2 - UI Screens**: ✅ Complete
- ChatListScreen
- ChatScreen
- DisputeChatScreen

**Phase 3 - Integration**: ✅ Complete
- ProductDetailScreen
- StoreDetailScreen
- OrderDetailScreen (seller side)
- Main navigation dengan unread badge

**Phase 4 - Testing**: 🔄 Ready for Testing
- Semua file created
- No compile errors
- Ready untuk backend integration testing

---

**Implementasi selesai!** 🎉

Fitur chat sudah fully implemented dan siap untuk testing dengan backend.
