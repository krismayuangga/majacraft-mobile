# Wishlist Implementation Guide - MajaCraft Mobile

## 📚 Overview

Dokumentasi lengkap untuk implementasi fitur Wishlist di MajaCraft Mobile App menggunakan Flutter + Dart.

---

## 🔌 Backend API Endpoints

### Base URL
```
Production: https://majacraft.id
Development: http://72.61.208.189:3001 (atau sesuai config)
```

### Endpoints

#### 1. Get All Wishlists
```http
GET /api/wishlist
Headers: Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "data": [
    {
      "id": "clxxx...",
      "userId": "user_123",
      "productId": "prod_456",
      "createdAt": "2024-01-01T10:00:00.000Z",
      "product": {
        "id": "prod_456",
        "name": "Batik Tulis Lasem",
        "slug": "batik-tulis-lasem",
        "price": 350000,
        "originalPrice": 500000,
        "image": "https://majacraft.id/uploads/products/batik-1.jpg",
        "images": ["url1", "url2"],
        "stock": 5,
        "rating": 4.8,
        "sold": 120,
        "store": {
          "name": "Toko Batik Jaya",
          "slug": "batik-jaya"
        }
      }
    }
  ]
}
```

#### 2. Add to Wishlist
```http
POST /api/wishlist
Headers: Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

Body:
{
  "productId": "prod_456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product added to wishlist",
  "data": {
    "id": "clxxx...",
    "userId": "user_123",
    "productId": "prod_456",
    "createdAt": "2024-01-01T10:00:00.000Z"
  }
}
```

#### 3. Remove from Wishlist
```http
DELETE /api/wishlist/{productId}
Headers: Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "success": true,
  "message": "Product removed from wishlist"
}
```

#### 4. Check if Product is Wishlisted
```http
GET /api/wishlist/{productId}
Headers: Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "isWishlisted": true
}
```

---

## 📁 File Structure

```
lib/
├── models/
│   └── wishlist.dart                 # Wishlist data model
├── services/
│   └── wishlist_service.dart         # API calls untuk wishlist
├── providers/
│   └── wishlist_provider.dart        # State management
├── screens/
│   └── wishlist_screen.dart          # Halaman list wishlist
└── examples/
    ├── wishlist_implementation_example.dart
    └── wishlist_screen_example.dart
```

---

## 🎯 Best Practices

### 1. **Optimistic Update** ✅ RECOMMENDED

Untuk UX yang lebih baik, gunakan optimistic update:
- Update UI **immediately** saat user tap wishlist button
- Jalankan API call di background
- Jika error, **revert** perubahan UI

**Implementasi:**
```dart
Future<bool> toggleWishlist(String productId, String token) async {
  final isCurrentlyWishlisted = _wishlistedProductIds.contains(productId);
  
  try {
    if (isCurrentlyWishlisted) {
      // Optimistic: Remove dari UI dulu
      _wishlistedProductIds.remove(productId);
      notifyListeners();
      
      // API call
      await _wishlistService.removeFromWishlist(productId, token);
      
      return false;
    } else {
      // Optimistic: Add ke UI dulu
      _wishlistedProductIds.add(productId);
      notifyListeners();
      
      // API call
      await _wishlistService.addToWishlist(productId, token);
      
      return true;
    }
  } catch (e) {
    // Revert jika error
    if (isCurrentlyWishlisted) {
      _wishlistedProductIds.add(productId);
    } else {
      _wishlistedProductIds.remove(productId);
    }
    notifyListeners();
    rethrow;
  }
}
```

**Pros:**
- UI feels instant & responsive
- Better UX, no loading delay
- User doesn't wait for API

**Cons:**
- Need error handling & revert logic
- Slightly more complex code

---

### 2. **Wait for API** (Alternative)

Update UI hanya **setelah** API success.

**Implementasi:**
```dart
setState(() => _isLoading = true);

try {
  await wishlistService.addToWishlist(productId, token);
  // Refresh data dari server
  await wishlistProvider.loadWishlists(token);
  
  showSnackBar('Berhasil ditambahkan');
} catch (e) {
  showSnackBar('Gagal: $e');
} finally {
  setState(() => _isLoading = false);
}
```

**Pros:**
- Simple & straightforward
- Always in sync with server
- No revert logic needed

**Cons:**
- User harus tunggu API response
- Feels slower (bad UX)

---

### 3. **Caching Strategy**

Untuk mengurangi API calls:

**Load once on app start:**
```dart
// In AuthProvider after login success
await wishlistProvider.loadWishlists(token);
```

**Use Set untuk fast lookup:**
```dart
Set<String> _wishlistedProductIds = {};

bool isWishlisted(String productId) {
  return _wishlistedProductIds.contains(productId); // O(1) lookup
}
```

**Invalidate cache when:**
- User login/logout
- Wishlist list screen refresh
- After 5-10 minutes (optional)

---

## 🔥 Performance Tips

### 1. **Use Set instead of List for lookup**
```dart
// ❌ SLOW - O(n)
List<String> ids = ['id1', 'id2', ...];
bool isWishlisted = ids.contains(productId);

// ✅ FAST - O(1)
Set<String> ids = {'id1', 'id2', ...};
bool isWishlisted = ids.contains(productId);
```

### 2. **Batch Load Wishlists**
```dart
// Load all wishlists once
await wishlistProvider.loadWishlists(token);

// Then use local state for checks
bool isWishlisted = wishlistProvider.isProductWishlisted(productId);
```

### 3. **Debounce Toggle**
Prevent spam clicks:
```dart
bool _isToggling = false;

Future<void> _toggleWishlist() async {
  if (_isToggling) return; // Prevent spam
  
  setState(() => _isToggling = true);
  try {
    await wishlistProvider.toggleWishlist(productId, token);
  } finally {
    setState(() => _isToggling = false);
  }
}
```

---

## 🎨 UI/UX Recommendations

### 1. **Visual Feedback**
```dart
IconButton(
  icon: isWishlisted 
    ? Icon(Icons.favorite, color: Colors.red)       // Filled
    : Icon(Icons.favorite_border, color: Colors.grey), // Outline
  onPressed: _toggleWishlist,
)
```

### 2. **Loading State**
```dart
_isToggling
  ? SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    )
  : Icon(isWishlisted ? Icons.favorite : Icons.favorite_border)
```

### 3. **Success Feedback**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('✓ Ditambahkan ke wishlist'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);
```

### 4. **Login Prompt**
```dart
if (!isAuthenticated) {
  _showLoginDialog();
  return;
}
```

---

## 🚀 Integration Checklist

- [ ] Add `WishlistProvider` to `main.dart` MultiProvider
- [ ] Call `loadWishlists()` after user login
- [ ] Clear wishlist on logout
- [ ] Implement toggle in Product Detail screen
- [ ] Create Wishlist List screen
- [ ] Add navigation to Wishlist from Profile/Menu
- [ ] Test optimistic update behavior
- [ ] Test error handling & revert
- [ ] Test with slow network (throttle)
- [ ] Test login required flow

---

## 🔧 Setup in main.dart

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        // ... other providers
      ],
      child: MyApp(),
    ),
  );
}
```

---

## 📝 Usage Examples

### In Product Detail Screen
```dart
import 'package:provider/provider.dart';

Consumer<WishlistProvider>(
  builder: (context, wishlistProvider, child) {
    final isWishlisted = wishlistProvider.isProductWishlisted(productId);
    
    return IconButton(
      icon: Icon(
        isWishlisted ? Icons.favorite : Icons.favorite_border,
        color: isWishlisted ? Colors.red : Colors.grey,
      ),
      onPressed: () async {
        final token = context.read<AuthProvider>().token;
        if (token == null) {
          // Show login dialog
          return;
        }
        
        await wishlistProvider.toggleWishlist(productId, token);
      },
    );
  },
)
```

### In Profile Screen
```dart
ListTile(
  leading: Icon(Icons.favorite),
  title: Text('Wishlist'),
  trailing: Text('${wishlistProvider.count}'),
  onTap: () {
    Navigator.pushNamed(context, '/wishlist');
  },
)
```

---

## ⚠️ Common Issues & Solutions

### Issue 1: Wishlist state not updating
**Solution:** Make sure provider is added to MultiProvider and `notifyListeners()` is called.

### Issue 2: "401 Unauthorized" error
**Solution:** Check token is valid and passed correctly in API calls.

### Issue 3: Duplicate products in wishlist
**Solution:** Backend has unique constraint (userId + productId). If duplicate, API will return error.

### Issue 4: Wishlist not persisting after app restart
**Solution:** Wishlist is stored in backend. Call `loadWishlists()` after login.

---

## 📚 References

- **API Documentation:** `/memories/repo/majacraft-api-reference.md`
- **Backend Repository:** https://github.com/krismayuangga/majacraft
- **Database Schema:** Prisma model `Wishlist` with unique constraint on `[userId, productId]`

---

## 💡 Recommendation: **Use Optimistic Update**

Untuk mobile app, **optimistic update adalah best practice** karena:
1. ✅ Feels instant & responsive
2. ✅ Better user experience
3. ✅ Handles network latency well
4. ✅ Standard practice in modern apps (Instagram, Twitter, etc.)

Trade-off nya:
- ⚠️ Perlu error handling yang baik
- ⚠️ Code sedikit lebih complex

**But it's worth it for better UX!**

---

**Created:** 2024-07-26  
**Version:** 1.0  
**Maintainer:** MajaCraft Team
