# 🏗️ MajaCraft Mobile - Architecture Documentation

## System Architecture

### Overview
MajaCraft Mobile adalah Flutter application yang menggunakan Provider pattern untuk state management, clean architecture dengan separation of concerns (screens, services, models), dan Material Design 3 untuk UI/UX.

---

## 🎯 Tech Stack

### Core
- **Framework:** Flutter 3.32.6 (stable)
- **Language:** Dart SDK 3.8.1
- **State Management:** Provider 6.1.1
- **UI:** Material Design 3

### Key Packages
- **HTTP Client:** http 1.2.0, http_parser 4.0.2
- **Image Picker:** image_picker 1.0.7
- **Storage:** Shared Preferences (for local storage)
- **Navigation:** Flutter Navigator 2.0 (built-in)

---

## 📁 Directory Structure

```
majacraft-mobile/
├── lib/
│   ├── main.dart                         # App entry point, runApp()
│   │
│   ├── config/                           # Configuration
│   │   └── api_config.dart              # API base URL, constants
│   │
│   ├── providers/                        # State management
│   │   └── auth_provider.dart           # Authentication state (ChangeNotifier)
│   │
│   ├── services/                         # Business logic & API calls
│   │   ├── api_service.dart             # HTTP client wrapper
│   │   ├── auth_service.dart            # Auth API (login, register)
│   │   ├── region_service.dart          # Region cascade API
│   │   ├── postal_code_service.dart     # Postal code lookup
│   │   └── upload_service.dart          # Image upload multipart
│   │
│   ├── models/                           # Data models
│   │   ├── user.dart                    # User model with fromJson
│   │   ├── store.dart                   # Store model
│   │   └── region.dart                  # Province, Regency, District, Village
│   │
│   ├── data/                             # Static data
│   │   └── bank_list.dart               # 102+ Indonesia banks list
│   │
│   ├── screens/                          # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart        # Login page
│   │   │   └── register_screen.dart     # Register page
│   │   │
│   │   ├── buyer/
│   │   │   └── home_screen.dart         # Buyer dashboard (coming soon)
│   │   │
│   │   ├── seller/
│   │   │   └── studio_screen.dart       # Studio Seniman (5 tabs)
│   │   │       ├── studio_ringkasan_tab.dart      # Home/overview
│   │   │       ├── studio_karya_tab.dart          # Products
│   │   │       ├── studio_pesanan_tab.dart        # Orders
│   │   │       ├── studio_saldo_tab.dart          # Balance
│   │   │       └── studio_pengaturan_tab.dart     # Settings
│   │   │
│   │   └── shared/
│   │       ├── address_form_screen.dart # Address management
│   │       └── add_address_screen.dart  # Add new address
│   │
│   └── widgets/                          # Reusable components
│       └── (custom widgets)
│
├── android/                              # Android native project
├── ios/                                  # iOS native project
├── assets/                               # Static assets
├── pubspec.yaml                          # Dependencies & config
└── test/                                 # Unit & widget tests
```

---

## 🔄 Data Flow

### Authentication Flow

```
App Start (main.dart)
  ↓
runApp(
  MultiProvider(
    providers: [AuthProvider],
    child: MyApp()
  )
)
  ↓
MyApp → MaterialApp
  ↓
AuthProvider.loadUserData()
  ↓
Shared Preferences → get('token')
  ↓
[Token exists?]
  ├─ Yes → Validate token → Set user → isAuthenticated = true
  └─ No  → user = null → isAuthenticated = false
  ↓
Consumer<AuthProvider> checks isAuthenticated
  ├─ true  → Navigate to HomeScreen or StudioScreen (by role)
  └─ false → Navigate to LoginScreen
```

### Login Flow

```
User enters email/password in LoginScreen
  ↓
AuthProvider.login(email, password)
  ↓
AuthService.login(email, password)
  ↓
POST https://majacraft.id/api/auth/mobile/login
  ↓
Backend validates credentials
  ↓
[Success?]
  ├─ Yes → Return { success: true, data: { token, user } }
  │         ↓
  │       AuthProvider stores token + user
  │         ↓
  │       Shared Preferences.setString('token', token)
  │       Shared Preferences.setString('user_data', json)
  │         ↓
  │       notifyListeners()
  │         ↓
  │       Navigator.pushReplacement() to StudioScreen
  │
  └─ No  → Return { success: false, error: message }
           ↓
         Show error SnackBar
```

### API Request Flow

```
Screen calls Service method
  ↓
Service → ApiService.get/post/patch()
  ↓
ApiService builds http.Request
  ├─ Get token from AuthProvider
  ├─ Add Authorization: Bearer <token>
  ├─ Add Content-Type: application/json
  └─ Send request
  ↓
Backend processes request
  ↓
Response handling
  ├─ 200-299 → Parse JSON → Return data
  ├─ 401 → Call AuthProvider.logout() → Navigate to Login
  └─ Other → Throw ApiException with message
```

### Studio Settings Data Flow (Example)

```
StudioPengaturanTab.initState()
  ↓
_initializeData()
  ├─ _loadProvinces() [with static cache, 5-min TTL]
  │   ↓
  │   RegionService.getProvinces()
  │   ↓
  │   GET https://emsifa.com/api-wilayah-indonesia/api/provinces.json
  │   ↓
  │   Parse List<Province> → Cache → setState()
  │
  └─ _loadStoreData()
      ↓
      ApiService.get('/api/studio/store')
      ↓
      Parse Store model
      ↓
      Restore selections (province, regency, district, village)
      ↓
      setState() → UI updates
      
User changes village
  ↓
_onVillageSelected(Village)
  ├─ _autoFillPostalCode()
  │   ↓
  │   PostalCodeService.searchByPlace(village.name + district.name)
  │   ↓
  │   GET https://kodepos.vercel.app/search
  │   ↓
  │   Parse postal code → Set _postalCodeController.text
  │
  └─ setState() → UI updates postal code field

User saves settings
  ↓
_saveInfoToko()
  ↓
ApiService.patch('/api/studio/store', body: {...})
  ↓
Backend updates database
  ↓
[Success?]
  ├─ Yes → Invalidate cache → Show success SnackBar
  └─ No  → Show error SnackBar
```

---

## 🧩 Architecture Patterns

### Provider Pattern (State Management)

**Purpose:** Global state management for authentication and user data

**Implementation:**
```dart
// 1. Define ChangeNotifier
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null && _token != null;
  
  Future<void> login(String email, String password) async {
    // API call
    // Store token + user
    notifyListeners(); // Trigger rebuild
  }
  
  Future<void> logout() async {
    _user = null;
    _token = null;
    // Clear storage
    notifyListeners();
  }
}

// 2. Provide at app root
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: MyApp(),
)

// 3. Consume in widgets
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (!authProvider.isAuthenticated) {
      return LoginScreen();
    }
    return HomeScreen();
  },
)

// or
final authProvider = Provider.of<AuthProvider>(context);
```

### Service Layer Pattern

**Purpose:** Separate business logic from UI, reusable API calls

**Structure:**
```dart
class ApiService {
  final String baseUrl;
  final AuthProvider authProvider;
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer ${authProvider.token}',
        'Content-Type': 'application/json',
      },
    );
    return _handleResponse(response);
  }
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      authProvider.logout();
      throw ApiException('Unauthorized');
    }
    // ... handle other cases
  }
}
```

### Model Pattern

**Purpose:** Type-safe data structures with JSON serialization

**Implementation:**
```dart
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? kycStatus;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.kycStatus,
  });
  
  // JSON deserialization
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'BUYER',
      kycStatus: json['kycStatus'],
    );
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'kycStatus': kycStatus,
    };
  }
}
```

### StatefulWidget with AutomaticKeepAliveClientMixin

**Purpose:** Prevent tab reload, maintain state when switching tabs

**Implementation:**
```dart
class StudioPengaturanTab extends StatefulWidget {
  @override
  State<StudioPengaturanTab> createState() => _StudioPengaturanTabState();
}

class _StudioPengaturanTabState extends State<StudioPengaturanTab>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep state alive
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // REQUIRED for keep alive
    return Scaffold(/* ... */);
  }
}
```

### Static Cache Pattern

**Purpose:** Reduce API calls, improve performance

**Implementation:**
```dart
class _StudioPengaturanTabState extends State<StudioPengaturanTab> {
  // Static cache shared across instances
  static List<Province>? _cachedProvinces;
  static Store? _cachedStore;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);
  
  Future<void> _loadProvinces() async {
    // Check cache validity
    if (_cachedProvinces != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      setState(() {
        _provinces = _cachedProvinces!;
      });
      return;
    }
    
    // Fetch from API
    _provinces = await _regionService.getProvinces();
    
    // Update cache
    _cachedProvinces = _provinces;
    _cacheTime = DateTime.now();
    
    setState(() {});
  }
  
  void _invalidateCache() {
    _cachedProvinces = null;
    _cachedStore = null;
    _cacheTime = null;
  }
}
```

---

## 🔐 Security

### Token Management
- JWT tokens stored in Shared Preferences (secure on device)
- Token sent in Authorization header: `Bearer <token>`
- 401 response triggers automatic logout
- Token expiry: 7 days (backend-managed)

### API Communication
- HTTPS only (https://majacraft.id)
- No sensitive data in logs
- Error messages sanitized for user display

---

## 📊 Performance Optimizations

### 1. Static Caching
- Province list cached for 5 minutes
- Store data cached to reduce API calls
- Cache invalidated on save operations

### 2. Keep Alive Tabs
- `AutomaticKeepAliveClientMixin` prevents tab reload
- State preserved when switching between tabs
- Reduces unnecessary API calls

### 3. Async Operations
- Sequential await for dependent operations
- Parallel processing where possible
- Loading states to prevent multiple requests

### 4. Image Optimization
- Images loaded with error handlers
- Network images cached automatically by Flutter
- Base URL concatenation for relative paths

---

## 🧪 Testing Strategy

### Unit Tests
- Test models (fromJson, toJson)
- Test services (API calls, error handling)
- Test utility functions

### Widget Tests
- Test screen rendering
- Test user interactions
- Test navigation flows

### Integration Tests
- Test complete user flows
- Test API integration
- Test state management

---

## 📦 Build & Deployment

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release  # For Play Store
```

### Signing Configuration
Located in `android/app/build.gradle`:
- Debug signing (auto-generated)
- Release signing (requires keystore setup)

---

## 🔄 Future Enhancements

### Planned Features
- [ ] Buyer product catalog & search
- [ ] Product detail pages
- [ ] Shopping cart & checkout
- [ ] Order tracking
- [ ] Chat/messaging
- [ ] Push notifications
- [ ] iOS support

### Technical Improvements
- [ ] Offline mode with local database (sqflite)
- [ ] Image caching optimization
- [ ] Pagination for large lists
- [ ] Background sync
- [ ] Analytics integration
- [ ] Crash reporting (Sentry/Firebase Crashlytics)

---

**Last Updated:** 2026-07-27  
**Architecture Version:** 2.0 (Flutter)  
**Flutter SDK:** 3.32.6 (stable)
const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
```

---

## 🔌 API Integration

### Base Configuration
**File:** `constants/config.ts`

```typescript
export const API_BASE_URL = 'http://72.61.208.189:3001';

export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/api/auth/mobile/login',
    REGISTER: '/api/auth/mobile/register',
    PROFILE: '/api/auth/profile',
  },
  PRODUCTS: {
    LIST: '/api/products',
    CREATE: '/api/products/create',
    UPDATE: '/api/products/:id',
    DELETE: '/api/products/:id',
  },
  ORDERS: {
    LIST: '/api/orders',
    DETAILS: '/api/orders/:id',
    UPDATE_STATUS: '/api/orders/:id/status',
  },
};
```

### Axios Instance
**File:** `lib/api.ts`

```typescript
import axios from 'axios';
import { getAuthToken } from './auth';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - Add auth token
api.interceptors.request.use(async (config) => {
  const token = await getAuthToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - Handle 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Logout user
      await logout();
    }
    return Promise.reject(error);
  }
);

export default api;
```

---

## 💾 Data Storage

### AsyncStorage Keys

```typescript
const AUTH_TOKEN_KEY = '@majacraft:auth_token';
const USER_DATA_KEY = '@majacraft:user_data';
```

### Storage Functions
**File:** `lib/auth.ts`

```typescript
// Save
await saveAuthToken(token);
await saveUserData(user);

// Get
const token = await getAuthToken();
const user = await getUserData();

// Remove
await removeAuthToken();
await removeUserData();

// Complete login
await login(token, user);  // Saves both

// Complete logout
await logout();  // Removes both
```

---

## 🎨 UI Patterns

### Screen Layout Pattern
```typescript
<View style={styles.container}>
  {/* Header */}
  <View style={styles.header}>
    <Text style={styles.title}>Screen Title</Text>
  </View>
  
  {/* Content */}
  <ScrollView style={styles.content}>
    {/* Main content */}
  </ScrollView>
  
  {/* Footer / Actions */}
  <View style={styles.footer}>
    <Button title="Action" onPress={handleAction} />
  </View>
</View>
```

### Form Pattern
```typescript
const [form, setForm] = useState({
  field1: '',
  field2: '',
});
const [errors, setErrors] = useState({});
const [loading, setLoading] = useState(false);

const handleSubmit = async () => {
  setLoading(true);
  setErrors({});
  
  try {
    const response = await api.post('/endpoint', form);
    // Handle success
  } catch (error) {
    setErrors({ general: error.message });
  } finally {
    setLoading(false);
  }
};
```

---

## 🔒 Security Practices

### 1. Token Storage
- ✅ JWT tokens stored in AsyncStorage (encrypted by OS)
- ✅ Never store passwords
- ✅ Token included in Authorization header

### 2. API Communication
- ✅ HTTPS in production (HTTP for local dev)
- ✅ Request/Response interceptors
- ✅ Error handling with user feedback

### 3. Input Validation
- ✅ Client-side validation for UX
- ✅ Backend validates all inputs (not trusted)
- ✅ Sanitize user inputs

---

## 📊 State Management Strategy

### Global State (Context API)
- Authentication state
- User data
- App-wide settings

### Local State (useState)
- Form data
- UI state (loading, errors)
- Component-specific data

### Server State (API calls)
- Products list
- Orders list
- User profile (synced with global state)

**No additional state management library** (Redux, MobX) untuk keep it simple.

---

## 🧪 Testing Strategy

### Manual Testing
1. Test all screens
2. Test auth flow
3. Test API integration
4. Test offline behavior
5. Test on real device

### Future: Automated Testing
- Unit tests: Jest
- Component tests: React Testing Library
- E2E tests: Detox

---

## 🚀 Build & Deployment

### Development
```bash
npm start          # Expo Go (SDK compatibility issues)
npx expo run:android  # Local development build
```

### Production
```bash
eas build --platform android --profile preview    # APK
eas build --platform android --profile production # AAB
```

### Profiles (eas.json)
- **development:** Internal distribution builds
- **preview:** APK for testing (tidak perlu Play Store)
- **production:** AAB for Play Store submission

---

## 🐛 Error Handling

### Pattern
```typescript
try {
  const response = await api.post('/endpoint', data);
  // Success
} catch (error: any) {
  if (error.response) {
    // Server responded with error
    console.error('API Error:', error.response.data);
    Alert.alert('Error', error.response.data.message);
  } else if (error.request) {
    // No response from server
    Alert.alert('Network Error', 'Cannot connect to server');
  } else {
    // Other errors
    Alert.alert('Error', error.message);
  }
}
```

---

## 📱 Navigation Structure

```
Index (/)
  └─ Redirect based on auth
      ├─ Not authenticated → /(auth)/login
      └─ Authenticated → /(tabs)/

(auth) Group
  ├─ login
  └─ register

(tabs) Group
  ├─ index (Home - WebView)
  ├─ upload (Upload Product)
  ├─ products (Seller Products)
  ├─ orders (Order Management)
  └─ profile (User Profile)
```

---

## 🔄 Future Improvements

### Short Term
- [ ] Add pull-to-refresh
- [ ] Add image caching
- [ ] Improve error messages
- [ ] Add loading skeletons

### Medium Term
- [ ] Offline support (queue actions)
- [ ] Push notification implementation
- [ ] In-app messaging
- [ ] Product search & filters

### Long Term
- [ ] iOS version
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Analytics integration

---

**Last Updated:** 2026-07-22
**Author:** AI Agent + krismayuangga
