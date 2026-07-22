# 🏗️ MajaCraft Mobile - Architecture Documentation

## System Architecture

### Overview
MajaCraft Mobile adalah React Native app yang dibangun dengan Expo SDK 54, menggunakan file-based routing (Expo Router) dan TypeScript untuk type safety.

---

## 🎯 Tech Stack

### Core
- **Framework:** Expo SDK 54.0.0
- **React:** 19.1.0
- **React Native:** 0.81.5
- **Language:** TypeScript 5.9.2
- **Navigation:** Expo Router 6.0.24

### Key Libraries
- **HTTP:** axios 1.7.9
- **Storage:** @react-native-async-storage/async-storage 2.2.0
- **WebView:** react-native-webview 13.15.0
- **Camera:** expo-camera 17.0.0
- **Image Picker:** expo-image-picker 17.0.11
- **Notifications:** expo-notifications 0.32.17

---

## 📁 Directory Structure

```
majacraft-mobile/
├── app/                          # Expo Router - file-based routing
│   ├── _layout.tsx              # Root layout (AuthProvider wrapper)
│   ├── index.tsx                # Entry point (redirects to login/tabs)
│   │
│   ├── (auth)/                  # Auth route group
│   │   ├── _layout.tsx          # Auth layout (Stack navigator)
│   │   ├── login.tsx            # Login screen
│   │   └── register.tsx         # Register screen
│   │
│   └── (tabs)/                  # Tabs route group (main app)
│       ├── _layout.tsx          # Tab layout (Bottom tabs)
│       ├── index.tsx            # Home (WebView to main site)
│       ├── upload.tsx           # Upload product screen
│       ├── products.tsx         # Seller products list
│       ├── orders.tsx           # Order management
│       └── profile.tsx          # User profile
│
├── lib/                          # Business logic & utilities
│   ├── AuthContext.tsx          # Global auth state (Context API)
│   ├── auth.ts                  # AsyncStorage auth helpers
│   └── api.ts                   # Axios instance with interceptors
│
├── constants/                    # Configuration constants
│   └── config.ts                # API URLs, endpoints
│
├── types/                        # TypeScript type definitions
│   └── index.ts                 # User, Product, Order interfaces
│
├── assets/                       # Static assets
│   ├── icon.png                 # App icon
│   ├── splash-icon.png          # Splash screen (removed for now)
│   └── android-icon-*.png       # Adaptive icons
│
├── app.json                      # Expo app configuration
├── eas.json                      # EAS Build profiles
├── package.json                  # Dependencies
├── tsconfig.json                 # TypeScript config
└── babel.config.js               # Babel config
```

---

## 🔄 Data Flow

### Authentication Flow

```
App Start
  ↓
_layout.tsx (AuthProvider)
  ↓
AuthContext.loadUserData()
  ↓
AsyncStorage.getItem('token')
  ↓
[Token exists?]
  ├─ Yes → Set user state → isAuthenticated = true
  └─ No  → user = null → isAuthenticated = false
  ↓
index.tsx checks isAuthenticated
  ├─ true  → Redirect to /(tabs)
  └─ false → Redirect to /(auth)/login
```

### Login Flow

```
User enters email/password in login.tsx
  ↓
POST /api/auth/mobile/login
  ↓
Backend validates credentials
  ↓
[Success?]
  ├─ Yes → Return { token, user }
  │         ↓
  │       AuthContext.login(token, user)
  │         ↓
  │       AsyncStorage.setItem('token')
  │       AsyncStorage.setItem('user_data')
  │         ↓
  │       router.replace('/(tabs)')
  │
  └─ No  → Show error message
```

### API Request Flow

```
Component calls API function
  ↓
api.ts (Axios instance)
  ↓
Request Interceptor
  ├─ Get token from AsyncStorage
  ├─ Add Authorization header
  └─ Send request
  ↓
Backend processes request
  ↓
Response Interceptor
  ├─ Success → Return data
  └─ 401 Error → Logout user
```

---

## 🧩 Component Architecture

### AuthContext Pattern

**Purpose:** Global authentication state management

**Location:** `lib/AuthContext.tsx`

**Provides:**
```typescript
{
  user: User | null,
  isLoading: boolean,
  isAuthenticated: boolean,
  login: (token, user) => Promise<void>,
  logout: () => Promise<void>,
  updateUser: (user) => Promise<void>
}
```

**Usage:**
```typescript
import { useAuth } from '../lib/AuthContext';

const { user, isAuthenticated, logout } = useAuth();
```

### Screen Components Pattern

**Structure:**
```typescript
// 1. Imports
import { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useAuth } from '../lib/AuthContext';

// 2. Component
export default function ScreenName() {
  // State
  const [data, setData] = useState([]);
  const { user } = useAuth();
  
  // Effects
  useEffect(() => {
    loadData();
  }, []);
  
  // Handlers
  const loadData = async () => {
    // fetch data
  };
  
  // Render
  return (
    <View style={styles.container}>
      {/* UI */}
    </View>
  );
}

// 3. Styles
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
