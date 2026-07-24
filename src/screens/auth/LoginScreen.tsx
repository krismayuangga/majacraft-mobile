import React, { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity,
  StyleSheet, KeyboardAvoidingView, Platform,
  Alert, ActivityIndicator, ScrollView,
} from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RouteProp } from '@react-navigation/native';
import {
  GoogleSignin,
  statusCodes,
} from '@react-native-google-signin/google-signin';
import { useAuth } from '../../lib/AuthContext';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { AuthResponse } from '../../types';
import { RootStackParamList } from '../../navigation/types';

GoogleSignin.configure({
  // Web Client ID dari project "General Apps" — sama dengan yang dipakai web app majacraft.id
  // Android OAuth client juga harus dibuat di project "General Apps" yang sama
  webClientId: '1089490083968-mpv497utnj95294vtjid83j8g83i0ooe.apps.googleusercontent.com',
  offlineAccess: true,
  forceCodeForRefreshToken: true,
});

type Props = {
  navigation: NativeStackNavigationProp<RootStackParamList, 'Login'>;
  route: RouteProp<RootStackParamList, 'Login'>;
};

export default function LoginScreen({ navigation, route }: Props) {
  const { login } = useAuth();
  const [email, setEmail]         = useState('');
  const [password, setPassword]   = useState('');
  const [loading, setLoading]     = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  const handleLoginSuccess = async (token: string, user: any) => {
    await login(token, user);
    navigation.goBack(); // MainWebView useEffect akan handle redirect
  };

  // ─── Google Sign-In ─────────────────────────────────────────────────────────
  const handleGoogleLogin = async () => {
    setGoogleLoading(true);
    try {
      await GoogleSignin.hasPlayServices();
      const userInfo = await GoogleSignin.signIn();
      const idToken = userInfo.data?.idToken;
      if (!idToken) throw new Error('Gagal mendapatkan Google token');

      const res = await api.post<AuthResponse['data']>(API_ENDPOINTS.GOOGLE_LOGIN, {
        idToken,
      });

      if (res.data?.token && res.data?.user) {
        await handleLoginSuccess(res.data.token, res.data.user);
      } else {
        Alert.alert('Login Google Gagal', res.message ?? 'Response tidak valid');
      }
    } catch (err: any) {
      if (err.code === statusCodes.SIGN_IN_CANCELLED) {
        // user cancel, no action needed
      } else if (err.code === statusCodes.IN_PROGRESS) {
        Alert.alert('Info', 'Google Sign-In sedang berjalan');
      } else if (err.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
        Alert.alert('Error', 'Google Play Services tidak tersedia');
      } else {
        Alert.alert('Error', err.message ?? 'Gagal login dengan Google');
      }
    } finally {
      setGoogleLoading(false);
    }
  };

  // ─── Email/Password Login ────────────────────────────────────────────────────
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
        await handleLoginSuccess(res.data.token, res.data.user);
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
        {/* Tombol tutup modal */}
        <TouchableOpacity style={styles.closeBtn} onPress={() => navigation.goBack()}>
          <Text style={styles.closeText}>✕</Text>
        </TouchableOpacity>

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
            disabled={loading || googleLoading}
          >
            {loading
              ? <ActivityIndicator color="#fff" />
              : <Text style={styles.btnText}>Masuk</Text>
            }
          </TouchableOpacity>

          {/* Divider */}
          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>atau</Text>
            <View style={styles.dividerLine} />
          </View>

          {/* Google Sign-In */}
          <TouchableOpacity
            style={[styles.googleBtn, googleLoading && styles.btnDisabled]}
            onPress={handleGoogleLogin}
            disabled={loading || googleLoading}
          >
            {googleLoading ? (
              <ActivityIndicator color="#1f2937" />
            ) : (
              <>
                <Text style={styles.googleIcon}>G</Text>
                <Text style={styles.googleText}>Masuk dengan Google</Text>
              </>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => navigation.replace('Register')}
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
  container: { flexGrow: 1, justifyContent: 'center', padding: 24, paddingTop: 60 },
  closeBtn: { position: 'absolute', top: 16, right: 16, padding: 8 },
  closeText: { color: '#6b7280', fontSize: 20, fontWeight: '600' },
  header: { alignItems: 'center', marginBottom: 40 },
  brand: { fontSize: 32, fontWeight: '800', color: '#f5f5f0', letterSpacing: 4 },
  brandAccent: { color: '#d97706' },
  subtitle: { color: '#9ca3af', marginTop: 4, fontSize: 13 },
  form: { gap: 12 },
  label: { color: '#d1d5db', fontSize: 13, fontWeight: '600', marginBottom: 4 },
  divider: { flexDirection: 'row', alignItems: 'center', marginVertical: 4 },
  dividerLine: { flex: 1, height: 1, backgroundColor: '#374151' },
  dividerText: { color: '#6b7280', fontSize: 12, marginHorizontal: 12 },
  googleBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    backgroundColor: '#f5f5f0', borderRadius: 12, padding: 14, gap: 10,
  },
  googleIcon: {
    fontSize: 18, fontWeight: '700', color: '#ea4335',
  },
  googleText: { color: '#1f2937', fontWeight: '600', fontSize: 15 },
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
