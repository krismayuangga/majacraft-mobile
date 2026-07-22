import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useAuth } from '../../lib/AuthContext';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { AuthResponse } from '../../types';

export default function Login() {
  const router = useRouter();
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async () => {
    if (!email.trim()) {
      Alert.alert('Error', 'Email wajib diisi');
      return;
    }

    // Validasi format email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      Alert.alert('Error', 'Format email tidak valid');
      return;
    }

    if (!password.trim()) {
      Alert.alert('Error', 'Password wajib diisi');
      return;
    }

    setIsLoading(true);
    try {
      const response = await api.post<AuthResponse>(API_ENDPOINTS.LOGIN, {
        email: email.toLowerCase().trim(),
        password: password.trim(),
      });

      if (response.success && response.data?.user && response.data?.token) {
        await login(response.data.token, response.data.user);
        router.replace('/(tabs)');
      } else {
        Alert.alert('Error', response.message || 'Login gagal');
      }
    } catch (error: any) {
      console.error('Login error:', error);
      // Error dari interceptor sudah di-format
      const errorMessage = error.message || 'Terjadi kesalahan saat login';
      Alert.alert('Login Gagal', errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.container}
    >
      <StatusBar style="dark" />
      <View style={styles.content}>
        <Text style={styles.title}>MajaCraft</Text>
        <Text style={styles.subtitle}>Masuk ke akun Anda</Text>

        <View style={styles.form}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Email</Text>
            <TextInput
              style={styles.input}
              placeholder="nama@email.com"
              keyboardType="email-address"
              value={email}
              onChangeText={setEmail}
              editable={!isLoading}
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Password</Text>
            <TextInput
              style={styles.input}
              placeholder="Masukkan password Anda"
              secureTextEntry
              value={password}
              onChangeText={setPassword}
              editable={!isLoading}
              autoCapitalize="none"
            />
          </View>

          <TouchableOpacity
            style={[styles.button, isLoading && styles.buttonDisabled]}
            onPress={handleLogin}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Masuk</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.linkButton}
            onPress={() => router.push('/(auth)/register')}
            disabled={isLoading}
          >
            <Text style={styles.linkText}>
              Belum punya akun? <Text style={styles.linkTextBold}>Daftar</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
  },
  content: {
    paddingHorizontal: 24,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#007AFF',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 40,
  },
  form: {
    width: '100%',
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    backgroundColor: '#f9f9f9',
  },
  button: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 10,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  linkButton: {
    marginTop: 20,
    alignItems: 'center',
  },
  linkText: {
    fontSize: 14,
    color: '#666',
  },
  linkTextBold: {
    color: '#007AFF',
    fontWeight: '600',
  },
});
