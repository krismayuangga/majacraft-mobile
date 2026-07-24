import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import { API_BASE_URL } from '../constants/config';
import { getAuthToken } from './auth';
import { ApiResponse } from '../types';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30_000,
      headers: { 'Content-Type': 'application/json' },
    });

    // Attach JWT on every request
    this.client.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        const token = await getAuthToken();
        if (token) config.headers.Authorization = `Bearer ${token}`;
        return config;
      },
      (error) => Promise.reject(error),
    );

    // Normalise error responses
    this.client.interceptors.response.use(
      (response) => response.data,
      (error) => {
        const message =
          error.response?.data?.error ||
          error.response?.data?.message ||
          error.message ||
          'Terjadi kesalahan jaringan';
        return Promise.reject(new Error(message));
      },
    );
  }

  async get<T>(url: string, params?: object): Promise<ApiResponse<T>> {
    return this.client.get(url, { params }) as Promise<ApiResponse<T>>;
  }

  async post<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    return this.client.post(url, data) as Promise<ApiResponse<T>>;
  }

  async patch<T>(url: string, data?: object): Promise<ApiResponse<T>> {
    return this.client.patch(url, data) as Promise<ApiResponse<T>>;
  }

  async delete<T>(url: string): Promise<ApiResponse<T>> {
    return this.client.delete(url) as Promise<ApiResponse<T>>;
  }

  /** Multipart upload (gambar produk) */
  async upload<T>(url: string, formData: FormData): Promise<ApiResponse<T>> {
    return this.client.post(url, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }) as Promise<ApiResponse<T>>;
  }
}

export default new ApiClient();
