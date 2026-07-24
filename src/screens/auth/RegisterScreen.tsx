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

type Props = { navigation: NativeStackNavigationProp<AuthStackParamList, 'Register'> };

export default function RegisterScreen({ navigation }: Props) {
  const { login } = useAuth();
  const [name,     setName]     = useState('');
  const [email,    setEmail]    = useState('');
  const [password, setPassword] = useState('');
  const [confirm,  setConfirm]  = useState('');
  const [loading,  setLoading]  = useState(false);

  const handleRegister = async () => {
    if (!name.trim() || !email.trim() || !password.trim()) {
      return Alert.alert('Error', 'Semua field wajib diisi');
    }
    if (password !== confirm) {
      return Alert.alert('Error', 'Konfirmasi password tidak cocok');
    }
    if (password.length < 8) {
      return Alert.alert('Error', 'Password minimal 8 karakter');
    }

    setLoading(true);
    try {
      const res = await api.post<AuthResponse['data']>(API_ENDPOINTS.REGISTER, {
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password,
      });
      if (res.data?.token && res.data?.user) {
        await login(res.data.token, res.data.user);
      } else {
        Alert.alert('Gagal', res.message ?? 'Registrasi gagal');
      }
    } catch (err: any) {
      Alert.alert('Error', err.message);
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
        <View style={styles.header}>
          <Text style={styles.brand}>MAJA<Text style={styles.brandAccent}>CRAFT</Text></Text>
          <Text style={styles.subtitle}>Buat akun baru</Text>
        </View>

        <View style={styles.form}>
          {[
            { label: 'Nama Lengkap', value: name, set: setName, placeholder: 'Nama Anda', secure: false, kbd: 'default' as const },
            { label: 'Email', value: email, set: setEmail, placeholder: 'email@example.com', secure: false, kbd: 'email-address' as const },
            { label: 'Password', value: password, set: setPassword, placeholder: 'Min. 8 karakter', secure: true, kbd: 'default' as const },
            { label: 'Konfirmasi Password', value: confirm, set: setConfirm, placeholder: 'Ulangi password', secure: true, kbd: 'default' as const },
          ].map(f => (
            <View key={f.label}>
              <Text style={styles.label}>{f.label}</Text>
              <TextInput
                style={styles.input}
                value={f.value}
                onChangeText={f.set}
                placeholder={f.placeholder}
                placeholderTextColor="#9ca3af"
                secureTextEntry={f.secure}
                keyboardType={f.kbd}
                autoCapitalize="none"
                autoCorrect={false}
              />
            </View>
          ))}

          <TouchableOpacity
            style={[styles.btn, loading && styles.btnDisabled]}
            onPress={handleRegister}
            disabled={loading}
          >
            {loading
              ? <ActivityIndicator color="#fff" />
              : <Text style={styles.btnText}>Daftar</Text>
            }
          </TouchableOpacity>

          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.link}>
            <Text style={styles.linkText}>
              Sudah punya akun? <Text style={styles.linkAccent}>Masuk</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex:        { flex: 1, backgroundColor: '#0f0f0f' },
  container:   { flexGrow: 1, justifyContent: 'center', padding: 24 },
  header:      { alignItems: 'center', marginBottom: 32 },
  brand:       { fontSize: 28, fontWeight: '800', color: '#f5f5f0', letterSpacing: 4 },
  brandAccent: { color: '#d97706' },
  subtitle:    { color: '#9ca3af', marginTop: 4, fontSize: 13 },
  form:        { gap: 4 },
  label:       { color: '#d1d5db', fontSize: 13, fontWeight: '600', marginBottom: 4, marginTop: 12 },
  input: {
    backgroundColor: '#1c1c1e',
    borderWidth: 1, borderColor: '#374151',
    borderRadius: 12, padding: 14,
    color: '#f5f5f0', fontSize: 15,
  },
  btn:         { backgroundColor: '#d97706', borderRadius: 12, padding: 16, alignItems: 'center', marginTop: 20 },
  btnDisabled: { opacity: 0.6 },
  btnText:     { color: '#fff', fontWeight: '700', fontSize: 16 },
  link:        { alignItems: 'center', marginTop: 16 },
  linkText:    { color: '#9ca3af', fontSize: 14 },
  linkAccent:  { color: '#d97706', fontWeight: '600' },
});
