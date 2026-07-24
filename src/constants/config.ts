/**
 * MajaCraft Mobile — API Configuration
 *
 * Android Emulator: 10.0.2.2 maps to host machine localhost
 * iOS Simulator:    127.0.0.1 / localhost
 * Physical Device:  gunakan IP LAN host machine (misal 192.168.x.x:3030)
 */

const DEV_HOST_ANDROID = 'http://10.0.2.2:3030';
const DEV_HOST_IOS     = 'http://localhost:3030';
const PROD_URL         = 'https://majacraft.id';

import { Platform } from 'react-native';

export const API_BASE_URL = __DEV__
  ? Platform.OS === 'android' ? DEV_HOST_ANDROID : DEV_HOST_IOS
  : PROD_URL;

export const WEB_BASE_URL = __DEV__ ? API_BASE_URL : PROD_URL;

export const API_ENDPOINTS = {
  // ─── Auth (mobile JWT) ──────────────────────────────────────────────────
  LOGIN:          '/api/auth/mobile/login',
  REGISTER:       '/api/auth/mobile/register',
  ME:             '/api/auth/mobile/me',
  WEBVIEW_TOKEN:  '/api/auth/mobile/webview-token', // JWT → WebView session cookie

  // ─── User ────────────────────────────────────────────────────────────────
  PROFILE:        '/api/users/me',
  KYC:            '/api/users/kyc',
  UPGRADE_SELLER: '/api/users/upgrade-seller',

  // ─── Products (public) ───────────────────────────────────────────────────
  PRODUCTS:               '/api/products',
  PRODUCT_DETAIL: (slug: string) => `/api/products/${slug}`,
  CATEGORIES:             '/api/categories',

  // ─── Studio (seller) ─────────────────────────────────────────────────────
  MY_PRODUCTS:             '/api/studio/products',
  MY_PRODUCT_DETAIL: (id: string) => `/api/studio/products/${id}`,
  CREATE_PRODUCT:          '/api/studio/products',           // POST
  UPDATE_PRODUCT: (id: string) => `/api/studio/products/${id}`,
  DELETE_PRODUCT: (id: string) => `/api/studio/products/${id}`,
  STUDIO_ORDERS:           '/api/studio/orders',
  SHIP_ORDER: (id: string) => `/api/studio/orders/${id}/ship`,
  STUDIO_BALANCE:          '/api/studio/balance',
  STUDIO_STORE:            '/api/studio/store',

  // ─── Orders (buyer) ──────────────────────────────────────────────────────
  ORDERS:                  '/api/orders',
  ORDER_DETAIL: (id: string) => `/api/orders/${id}`,
  CONFIRM_ORDER: (id: string) => `/api/orders/${id}/confirm`,
  CANCEL_ORDER: (id: string)  => `/api/orders/${id}/cancel`,

  // ─── Upload ──────────────────────────────────────────────────────────────
  UPLOAD: '/api/upload',

  // ─── Notifications ───────────────────────────────────────────────────────
  NOTIFICATIONS:          '/api/notifications',
  NOTIFICATION_READ: (id: string) => `/api/notifications/${id}`,
  REGISTER_PUSH_DEVICE:   '/api/notifications/register-device',
};

export const UPLOAD_CONFIG = {
  MAX_IMAGES_PER_PRODUCT: 5,
  MAX_IMAGE_SIZE_MB: 5,
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/webp'],
};

/** Web pages loaded in WebView (buyer side) */
export const WEB_PAGES = {
  HOME:      '/',
  PRODUCTS:  '/produk',
  CART:      '/keranjang',
  ORDERS:    '/pesanan',
  WISHLIST:  '/wishlist',
  PROFILE:   '/akun',
  CHAT:      '/chat',
  NOTIF:     '/akun/notifikasi',
  LOGIN:     '/masuk',
};
