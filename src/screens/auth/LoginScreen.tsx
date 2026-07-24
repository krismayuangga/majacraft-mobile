import React, { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, KeyboardAvoidingView, Platform,
  Alert, ActivityIndicator, ScrollView,
} from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../../lib/AuthContext';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { AuthResponse } from '../../types';
import { AuthStackParamList } from '../../navigation/types';

type Props = { navigation: NativeStackNavigationProp<AuthStackParamList, 'Login'> };

export default function LoginScreen({ navigation }: Props) {
  const { login } = useAuth();
  const [email, setEmail]       = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading]   = useState(false);

  const handleLogin = async () => {
    if (!email.trim() || !password.trim()) {
      Alert.alert('Error', 'Email dan password wajib diisi');
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      Alert.alert('Error', 'Format email tidak valid');
      return;
    }

    setLoading(true);
    try {
      const res = await api.post<AuthResponse['data']>(API_ENDPOINTS.LOGIN, {
        email: email.toLowerCase().trim(),
        password: password.trim(),
      });
      if (res.data?.token && res.data?.user) {
        await login(res.data.token, res.data.user);
        // Navigation handled by AppNavigator (user state change)
      } else {
        Alert.alert('Gagal', res.message ?? 'Login gagal');
      }
    } catch (err: any) {
      Alert.alert('Error', err.message ?? 'Terjadi kesalahan');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled">
        {/* Logo / Brand */}
        <View style={styles.header}>
          <Text style={styles.brand}>MAJA<Text style={styles.brandAccent}>CRAFT</Text></Text>
          <Text style={styles.subtitle}>Marketplace Kerajinan Indonesia</Text>
        </View>

        <View style={styles.form}>
          <Text style={styles.label}>Email</Text>
          <TextInput
            style={styles.input}
            value={email}
            onChangeText={setEmail}
            placeholder="email@example.com"
            placeholderTextColor="#9ca3af"
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
          />

          <Text style={styles.label}>Password</Text>
          <TextInput
            style={styles.input}
            value={password}
            onChangeText={setPassword}
            placeholder="Password"
            placeholderTextColor="#9ca3af"
            secureTextEntry
          />

          <TouchableOpacity
            style={[styles.btn, loading && styles.btnDisabled]}
            onPress={handleLogin}
            disabled={loading}
          >
            {loading
              ? <ActivityIndicator color="#fff" />
              : <Text style={styles.btnText}>Masuk</Text>
            }
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => navigation.navigate('Register')}
            style={styles.link}
          >
            <Text style={styles.linkText}>
              Belum punya akun? <Text style={styles.linkAccent}>Daftar sekarang</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, backgroundColor: '#0f0f0f' },
  container: { flexGrow: 1, justifyContent: 'center', padding: 24 },
  header: { alignItems: 'center', marginBottom: 40 },
  brand: { fontSize: 32, fontWeight: '800', color: '#f5f5f0', letterSpacing: 4 },
  brandAccent: { color: '#d97706' },
  subtitle: { color: '#9ca3af', marginTop: 4, fontSize: 13 },
  form: { gap: 12 },
  label: { color: '#d1d5db', fontSize: 13, fontWeight: '600', marginBottom: 4 },
  input: {
    backgroundColor: '#1c1c1e',
    borderWidth: 1,
    borderColor: '#374151',
    borderRadius: 12,
    padding: 14,
    color: '#f5f5f0',
    fontSize: 15,
    marginBottom: 8,
  },
  btn: {
    backgroundColor: '#d97706',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  btnDisabled: { opacity: 0.6 },
  btnText: { color: '#fff', fontWeight: '700', fontSize: 16 },
  link: { alignItems: 'center', marginTop: 16 },
  linkText: { color: '#9ca3af', fontSize: 14 },
  linkAccent: { color: '#d97706', fontWeight: '600' },
});
