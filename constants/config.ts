// API Configuration
export const API_BASE_URL = __DEV__ 
  ? 'http://localhost:3000' 
  : 'https://majacraft.id';

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/api/auth/login',
  REGISTER: '/api/auth/register',
  VERIFY_OTP: '/api/auth/verify-otp',
  REQUEST_OTP: '/api/auth/request-otp',
  LOGOUT: '/api/auth/logout',
  
  // User
  PROFILE: '/api/user/profile',
  UPDATE_PROFILE: '/api/user/update',
  
  // Products
  PRODUCTS: '/api/products',
  PRODUCT_DETAIL: (slug: string) => `/api/products/${slug}`,
  MY_PRODUCTS: '/api/products/my',
  CREATE_PRODUCT: '/api/products/create',
  UPDATE_PRODUCT: (id: string) => `/api/products/${id}`,
  DELETE_PRODUCT: (id: string) => `/api/products/${id}`,
  
  // Orders
  ORDERS: '/api/orders',
  ORDER_DETAIL: (id: string) => `/api/orders/${id}`,
  CREATE_ORDER: '/api/orders/create',
  UPDATE_ORDER_STATUS: (id: string) => `/api/orders/${id}/status`,
  
  // Reviews
  REVIEWS: '/api/reviews',
  REVIEW_DETAIL: (id: string) => `/api/reviews/${id}`,
  CREATE_REVIEW: '/api/reviews/create',
  
  // Upload
  UPLOAD: '/api/upload',
  
  // Notifications
  NOTIFICATIONS: '/api/notifications',
  MARK_READ: (id: string) => `/api/notifications/${id}/read`,
} as const;

// App Configuration
export const APP_CONFIG = {
  APP_NAME: 'MajaCraft',
  APP_VERSION: '1.0.0',
  SUPPORT_EMAIL: 'support@majacraft.id',
  TERMS_URL: 'https://majacraft.id/terms',
  PRIVACY_URL: 'https://majacraft.id/privacy',
} as const;

// Image Upload Configuration
export const UPLOAD_CONFIG = {
  MAX_IMAGE_SIZE: 5 * 1024 * 1024, // 5MB
  MAX_VIDEO_SIZE: 50 * 1024 * 1024, // 50MB
  MAX_IMAGES_PER_PRODUCT: 5,
  ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
  ALLOWED_VIDEO_TYPES: ['video/mp4', 'video/quicktime'],
} as const;
