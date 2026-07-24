import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../types';
import * as AuthStorage from './auth';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  isSeller: boolean;
  login: (token: string, user: User) => Promise<void>;
  logout: () => Promise<void>;
  updateUser: (user: User) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser]     = useState<User | null>(null);
  const [token, setToken]   = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const [t, u] = await Promise.all([
          AuthStorage.getAuthToken(),
          AuthStorage.getUserData(),
        ]);
        if (t && u) {
          setToken(t);
          setUser(u);
        }
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  const login = async (t: string, u: User) => {
    await AuthStorage.login(t, u);
    setToken(t);
    setUser(u);
  };

  const logout = async () => {
    await AuthStorage.logout();
    setToken(null);
    setUser(null);
  };

  const updateUser = async (u: User) => {
    await AuthStorage.saveUserData(u);
    setUser(u);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        isAuthenticated: !!user,
        isSeller: user?.role === 'SELLER' || user?.role === 'ADMIN',
        login,
        logout,
        updateUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
