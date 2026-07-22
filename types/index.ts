// Auth types
export interface Store {
  id: string;
  name: string;
  slug: string;
  province: string;
  isVerified: boolean;
  rating?: number;
  totalSold?: number;
}

export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  image?: string;
  role: 'BUYER' | 'SELLER' | 'ADMIN';
  status: 'ACTIVE' | 'SUSPENDED' | 'BANNED';
  kycStatus: 'UNVERIFIED' | 'PENDING' | 'VERIFIED' | 'REJECTED';
  store?: Store;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface RegisterInput {
  name: string;
  email: string;
  phone: string;
  password: string;
  role: 'BUYER' | 'SELLER';
  // Seller fields (optional)
  storeName?: string;
  province?: string;
  bankName?: string;
  bankAccount?: string;
}

// Product Types
export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  images: string[];
  status: 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';
  userId: string;
  user?: User;
  rating?: number;
  reviewCount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface ProductFormData {
  name: string;
  description: string;
  price: number;
  stock: number;
  category: string;
  images: string[];
}

// Order Types
export type OrderStatus = 
  | 'PENDING' 
  | 'PAYMENT_PENDING' 
  | 'PAID' 
  | 'PROCESSING' 
  | 'SHIPPED' 
  | 'COMPLETED' 
  | 'CANCELLED' 
  | 'REFUNDED';

export interface Order {
  id: string;
  orderNumber: string;
  userId: string;
  user?: User;
  productId: string;
  product?: Product;
  quantity: number;
  totalPrice: number;
  status: OrderStatus;
  shippingAddress: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateOrderInput {
  productId: string;
  quantity: number;
  shippingAddress: string;
  notes?: string;
}

// Review Types
export interface Review {
  id: string;
  productId: string;
  userId: string;
  user?: User;
  orderId: string;
  rating: number;
  comment: string;
  images?: string[];
  videoUrl?: string;
  helpfulCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface ReviewStats {
  totalReviews: number;
  averageRating: number;
  ratingBreakdown: {
    5: number;
    4: number;
    3: number;
    2: number;
    1: number;
  };
}

export interface CreateReviewInput {
  productId: string;
  orderId: string;
  rating: number;
  comment: string;
  images?: string[];
  videoUrl?: string;
}

// Notification Types
export interface Notification {
  id: string;
  userId: string;
  title: string;
  message: string;
  type: 'ORDER' | 'PRODUCT' | 'REVIEW' | 'SYSTEM';
  read: boolean;
  data?: Record<string, any>;
  createdAt: string;
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

// Upload Types
export interface UploadResponse {
  success: boolean;
  url: string;
  message?: string;
}
