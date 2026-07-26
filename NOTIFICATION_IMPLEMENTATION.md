# 🔔 Implementasi Fitur Notifikasi - MajaCraft Mobile

## Overview
Fitur notifikasi lengkap dengan badge counter, filter, dan integrasi backend API. Sesuai dengan implementasi di web version.

---

## 📦 Files Created

### 1. **lib/models/notification.dart**
- Model data untuk notifikasi
- `NotificationModel` class dengan fields: id, userId, title, message, type, read, data, createdAt
- `NotificationType` enum: ORDER, PRODUCT, REVIEW, SYSTEM
- JSON serialization (fromJson/toJson)

### 2. **lib/services/notification_service.dart**
- Service untuk API calls notifikasi
- **Methods:**
  - `getNotifications(token)` - Fetch all notifications
  - `markAsRead(notificationId, token)` - Mark single notification as read
  - `getUnreadCount(notifications)` - Count unread notifications
  - `markAllAsRead(notifications, token)` - Mark all as read

### 3. **lib/screens/notification_list_screen.dart**
- UI lengkap untuk daftar notifikasi
- **Features:**
  - Filter tabs: "Semua" dan "Belum Dibaca"
  - Badge count untuk unread notifications
  - "Tandai Semua Dibaca" action button
  - Pull-to-refresh untuk reload data
  - Empty state untuk kondisi tidak ada notifikasi
  - Relative time display menggunakan `timeago` package (Indonesian locale)
  - Highlight untuk notifikasi belum dibaca (background kuning muda)
  - Icon berbeda per tipe notifikasi
  - Tap handling untuk navigasi ke detail (order, product, review)

### 4. **lib/config/api_config.dart** (Updated)
- Tambah endpoint: `/api/notifications`
- Tambah function: `notificationRead(id)` untuk PATCH endpoint

### 5. **lib/widgets/custom_app_bar.dart** (Updated)
- Changed from StatelessWidget to StatefulWidget
- Auto-load unread count on init
- Dynamic badge display:
  - Small dot untuk count 1-9
  - Badge dengan angka untuk count 10-99
  - Badge "99+" untuk count > 99
- Navigate to NotificationListScreen on tap
- Reload count setelah kembali dari notification screen

### 6. **lib/screens/profile_screen.dart** (Updated)
- Import NotificationListScreen
- Update "Notifikasi" menu item to navigate ke NotificationListScreen
- Remove "coming soon" snackbar

---

## 🎨 UI/UX Features

### Notification Card
```dart
┌─────────────────────────────────────────────┐
│ [ICON]  Title (Bold jika unread)      [•]  │
│         Message (max 3 lines)                │
│         [Clock] "2 jam yang lalu"            │
└─────────────────────────────────────────────┘
```

### Badge Display
- **1-9**: Red dot
- **10-99**: Red badge dengan angka
- **100+**: Red badge "99+"

### Color Scheme
- **Background (unread)**: #FFF8F0 (cream kuning muda)
- **Background (read)**: White
- **Border (unread)**: #FFE8C5 (cream orange)
- **Border (read)**: #E0E0E0 (grey)
- **Primary**: #653611 (brown)

### Icons by Type
- **ORDER**: `shopping_bag_outlined` (brown)
- **PRODUCT**: `inventory_2_outlined` (blue)
- **REVIEW**: `rate_review_outlined` (amber)
- **SYSTEM**: `info_outline` (grey)

---

## 🔌 Backend API Integration

### Endpoints
```
GET  /api/notifications
     → Returns: { success: true, data: [NotificationModel] }

PATCH /api/notifications/:id
     → Mark notification as read
     → Returns: { success: true }
```

### Authentication
All requests require Bearer token in Authorization header.

---

## 📱 User Flow

1. **Home Screen**
   - User melihat badge merah di bell icon (jika ada notifikasi baru)
   - Badge menampilkan jumlah unread notifications

2. **Tap Bell Icon**
   - Navigate to NotificationListScreen
   - Auto-load notifications from API
   - Badge count updated

3. **Notification List Screen**
   - Default: Show all notifications
   - Toggle "Belum Dibaca" untuk filter unread only
   - Pull down untuk refresh
   - Tap "Tandai Semua Dibaca" untuk mark all as read

4. **Tap Notification Card**
   - Mark as read (jika belum dibaca)
   - Navigate ke detail page berdasarkan type:
     - ORDER → Order detail screen
     - PRODUCT → Product detail screen
     - REVIEW → Review screen
     - SYSTEM → Show info atau no action

5. **Return to Home**
   - Badge count updated (berkurang sesuai yang sudah dibaca)

---

## 🔄 State Management

- **Local State**: `_notifications`, `_filteredNotifications`, `_showUnreadOnly`
- **Provider**: AuthProvider untuk get token
- **Auto-reload**: Badge count di-reload setiap kembali dari notification screen

---

## 📦 Dependencies Added

```yaml
timeago: ^3.6.1  # Untuk relative time display (e.g., "2 jam yang lalu")
```

---

## 🧪 Testing Checklist

- [ ] Badge muncul saat ada notifikasi baru
- [ ] Badge count sesuai dengan jumlah unread
- [ ] Tap bell icon membuka notification list
- [ ] Filter "Semua" dan "Belum Dibaca" berfungsi
- [ ] Pull-to-refresh berhasil reload data
- [ ] "Tandai Semua Dibaca" berhasil mark all
- [ ] Tap notification mark as read dan navigate
- [ ] Empty state tampil saat tidak ada notifikasi
- [ ] Relative time display dalam bahasa Indonesia
- [ ] Badge update setelah kembali dari notification screen

---

## 🎯 Backend Requirements

Backend harus implement:

1. **GET /api/notifications**
   - Return array of notifications untuk current user
   - Filter by userId from JWT token
   - Order by createdAt DESC

2. **PATCH /api/notifications/:id**
   - Mark notification as read (set read = true)
   - Return success response

3. **Notification Creation Events**
   - Create notification on order status change
   - Create notification on product moderation
   - Create notification on review received
   - Create notification on system announcements

---

## 🚀 Future Enhancements

- [ ] Real-time notifications via WebSocket atau FCM (Firebase Cloud Messaging)
- [ ] Push notifications untuk background alerts
- [ ] Notification preferences/settings (enable/disable by type)
- [ ] Mark as read tanpa tap (mark on view)
- [ ] Delete notification feature
- [ ] Bulk actions (select multiple, delete selected)
- [ ] Notification sound/vibration settings
- [ ] In-app notification popup untuk real-time alerts

---

## 📝 Notes

- Indonesian locale sudah dikonfigurasi untuk timeago package
- Notification data field (Map<String, dynamic>) bisa digunakan untuk custom data per notification type
- Navigation ke detail screens masih TODO (print statement untuk debugging)
- Backend notification creation logic perlu diimplementasi di berbagai events

---

**Status**: ✅ Complete - Ready for testing  
**Date**: 2026-07-26  
**Version**: 1.0.0
