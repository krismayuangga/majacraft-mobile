// ─── User ─────────────────────────────────────────────────────────────────

export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  image?: string | null;
  role: 'BUYER' | 'SELLER' | 'ADMIN';
  status: 'ACTIVE' | 'BANNED' | 'SUSPENDED';
  kycStatus: 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
  store?: Store | null;
}

export interface Store {
  id: string;
  name: string;
  slug: string;
  province: string;
  isVerified: boolean;
}

// ─── Auth ──────────────────────────────────────────────────────────────────

export interface AuthResponse {
  success: boolean;
  message?: string;
  data?: {
    token: string;
    user: User;
  };
}

// ─── Product ──────────────────────────────────────────────────────────────

export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  price: number;
  originalPrice?: number | null;
  stock: number;
  isActive: boolean;
  isModerated: boolean;
  rejectionReason?: string | null;
  isFeatured: boolean;
  isFlashSale: boolean;
  material?: string | null;
  weight?: number | null;
  origin?: string | null;
  tags: string[];
  images: { url: string; isPrimary: boolean }[];
  category: { id: string; name: string; slug: string };
  store: { name: string; slug: string };
  rating: number;
  reviewCount: number;
  soldCount: number;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  icon?: string | null;
  imageUrl?: string | null;
  _count: { products: number };
}

// ─── Order ─────────────────────────────────────────────────────────────────

export type OrderStatus =
  | 'PENDING_PAYMENT' | 'PROCESSING' | 'SHIPPED'
  | 'DELIVERED' | 'COMPLETED' | 'CANCELLED' | 'REFUNDED';

export interface OrderItem {
  id: string;
  productName: string;
  price: number;
  qty: number;
  product?: { id: string; images: { url: string }[] } | null;
}

export interface Order {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  total: number;
  subtotal: number;
  shippingCost: number;
  createdAt: string;
  courierName?: string | null;
  trackingNumber?: string | null;
  items: OrderItem[];
}

// ─── Upload ────────────────────────────────────────────────────────────────

export interface PickedImage {
  uri: string;
  type?: string;
  fileName?: string;
  fileSize?: number;
  width?: number;
  height?: number;
}

// ─── API Response ──────────────────────────────────────────────────────────

export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pages: number;
}
