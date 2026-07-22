import AsyncStorage from '@react-native-async-storage/async-storage';
import { User } from '../types';

const AUTH_TOKEN_KEY = '@majacraft:auth_token';
const USER_DATA_KEY = '@majacraft:user_data';

/**
 * Save authentication token
 */
export async function saveAuthToken(token: string): Promise<void> {
  try {
    await AsyncStorage.setItem(AUTH_TOKEN_KEY, token);
  } catch (error) {
    console.error('Error saving auth token:', error);
    throw error;
  }
}

/**
 * Get authentication token
 */
export async function getAuthToken(): Promise<string | null> {
  try {
    return await AsyncStorage.getItem(AUTH_TOKEN_KEY);
  } catch (error) {
    console.error('Error getting auth token:', error);
    return null;
  }
}

/**
 * Remove authentication token
 */
export async function removeAuthToken(): Promise<void> {
  try {
    await AsyncStorage.removeItem(AUTH_TOKEN_KEY);
  } catch (error) {
    console.error('Error removing auth token:', error);
    throw error;
  }
}

/**
 * Save user data
 */
export async function saveUserData(user: User): Promise<void> {
  try {
    await AsyncStorage.setItem(USER_DATA_KEY, JSON.stringify(user));
  } catch (error) {
    console.error('Error saving user data:', error);
    throw error;
  }
}

/**
 * Get user data
 */
export async function getUserData(): Promise<User | null> {
  try {
    const data = await AsyncStorage.getItem(USER_DATA_KEY);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    console.error('Error getting user data:', error);
    return null;
  }
}

/**
 * Remove user data
 */
export async function removeUserData(): Promise<void> {
  try {
    await AsyncStorage.removeItem(USER_DATA_KEY);
  } catch (error) {
    console.error('Error removing user data:', error);
    throw error;
  }
}

/**
 * Check if user is authenticated
 */
export async function isAuthenticated(): Promise<boolean> {
  const token = await getAuthToken();
  return !!token;
}

/**
 * Logout user - clear all auth data
 */
export async function logout(): Promise<void> {
  try {
    await Promise.all([
      removeAuthToken(),
      removeUserData(),
    ]);
  } catch (error) {
    console.error('Error during logout:', error);
    throw error;
  }
}

/**
 * Login user - save token and user data
 */
export async function login(token: string, user: User): Promise<void> {
  try {
    await Promise.all([
      saveAuthToken(token),
      saveUserData(user),
    ]);
  } catch (error) {
    console.error('Error during login:', error);
    throw error;
  }
}
