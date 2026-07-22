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
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../lib/AuthContext';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { AuthResponse, RegisterInput } from '../../types';

type RoleType = 'BUYER' | 'SELLER';

const PROVINCES = [
  'Aceh', 'Bali', 'Banten', 'Bengkulu', 'DI Yogyakarta', 'DKI Jakarta',
  'Gorontalo', 'Jambi', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur',
  'Kalimantan Barat', 'Kalimantan Selatan', 'Kalimantan Tengah',
  'Kalimantan Timur', 'Kalimantan Utara', 'Kepulauan Bangka Belitung',
  'Kepulauan Riau', 'Lampung', 'Maluku', 'Maluku Utara', 'Nusa Tenggara Barat',
  'Nusa Tenggara Timur', 'Papua', 'Papua Barat', 'Papua Barat Daya',
  'Papua Pegunungan', 'Papua Selatan', 'Papua Tengah', 'Riau',
  'Sulawesi Barat', 'Sulawesi Selatan', 'Sulawesi Tengah', 'Sulawesi Tenggara',
  'Sulawesi Utara', 'Sumatera Barat', 'Sumatera Selatan', 'Sumatera Utara',
];

export default function Register() {
  const router = useRouter();
  const { login } = useAuth();
  
  // Basic fields
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [role, setRole] = useState<RoleType>('BUYER');
  
  // Seller fields
  const [storeName, setStoreName] = useState('');
  const [province, setProvince] = useState('');
  const [bankName, setBankName] = useState('');
  const [bankAccount, setBankAccount] = useState('');
  
  const [showProvinceDropdown, setShowProvinceDropdown] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const validateForm = () => {
    if (!name.trim()) {
      Alert.alert('Error', 'Nama wajib diisi');
      return false;
    }
    
    if (name.trim().length < 2) {
      Alert.alert('Error', 'Nama minimal 2 karakter');
      return false;
    }

    // Validasi email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email.trim() || !emailRegex.test(email)) {
      Alert.alert('Error', 'Format email tidak valid');
      return false;
    }

    // Validasi phone
    const phoneRegex = /^(\+62|08)[0-9]{8,12}$/;
    if (!phone.trim() || !phoneRegex.test(phone.trim())) {
      Alert.alert('Error', 'Format nomor HP tidak valid (contoh: 081234567890)');
      return false;
    }

    // Validasi password
    if (!password || password.length < 8) {
      Alert.alert('Error', 'Password minimal 8 karakter');
      return false;
    }

    if (password !== confirmPassword) {
      Alert.alert('Error', 'Password dan konfirmasi password tidak sama');
      return false;
    }

    // Validasi seller fields
    if (role === 'SELLER') {
      if (!storeName.trim()) {
        Alert.alert('Error', 'Nama toko wajib diisi untuk Seniman');
        return false;
      }
      if (!province) {
        Alert.alert('Error', 'Provinsi wajib dipilih untuk Seniman');
        return false;
      }
      if (!bankName.trim()) {
        Alert.alert('Error', 'Nama bank wajib diisi untuk Seniman');
        return false;
      }
      if (!bankAccount.trim()) {
        Alert.alert('Error', 'Nomor rekening wajib diisi untuk Seniman');
        return false;
      }
    }

    return true;
  };

  const handleRegister = async () => {
    if (!validateForm()) return;

    setIsLoading(true);
    try {
      const registerData: RegisterInput = {
        name: name.trim(),
        email: email.toLowerCase().trim(),
        phone: phone.trim(),
        password,
        role,
      };

      // Add seller fields if role is SELLER
      if (role === 'SELLER') {
        registerData.storeName = storeName.trim();
        registerData.province = province;
        registerData.bankName = bankName.trim();
        registerData.bankAccount = bankAccount.trim();
      }

      const response = await api.post<AuthResponse>(API_ENDPOINTS.REGISTER, registerData);

      if (response.success && response.data?.user && response.data?.token) {
        await login(response.data.token, response.data.user);
        Alert.alert('Berhasil', 'Akun berhasil dibuat!', [
          { text: 'OK', onPress: () => router.replace('/(tabs)') },
        ]);
      } else {
        Alert.alert('Error', response.message || 'Registrasi gagal');
      }
    } catch (error: any) {
      console.error('Register error:', error);
      // Error dari interceptor sudah di-format
      const errorMessage = error.message || 'Terjadi kesalahan saat registrasi';
      Alert.alert('Registrasi Gagal', errorMessage);
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
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.content}>
          <Text style={styles.title}>Daftar MajaCraft</Text>
          <Text style={styles.subtitle}>Buat akun baru untuk mulai berbelanja atau berjualan</Text>

          {/* Role Selection */}
          <View style={styles.roleContainer}>
            <Text style={styles.label}>Daftar sebagai:</Text>
            <View style={styles.roleButtons}>
              <TouchableOpacity
                style={[
                  styles.roleButton,
                  role === 'BUYER' && styles.roleButtonActive,
                ]}
                onPress={() => setRole('BUYER')}
                disabled={isLoading}
              >
                <Ionicons
                  name="cart"
                  size={24}
                  color={role === 'BUYER' ? '#007AFF' : '#666'}
                />
                <Text
                  style={[
                    styles.roleButtonText,
                    role === 'BUYER' && styles.roleButtonTextActive,
                  ]}
                >
                  Pembeli
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[
                  styles.roleButton,
                  role === 'SELLER' && styles.roleButtonActive,
                ]}
                onPress={() => setRole('SELLER')}
                disabled={isLoading}
              >
                <Ionicons
                  name="storefront"
                  size={24}
                  color={role === 'SELLER' ? '#007AFF' : '#666'}
                />
                <Text
                  style={[
                    styles.roleButtonText,
                    role === 'SELLER' && styles.roleButtonTextActive,
                  ]}
                >
                  Seniman
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* Basic Fields */}
          <View style={styles.form}>
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Nama Lengkap</Text>
              <TextInput
                style={styles.input}
                placeholder="Masukkan nama lengkap"
                value={name}
                onChangeText={setName}
                editable={!isLoading}
              />
            </View>

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
              <Text style={styles.label}>Nomor HP</Text>
              <TextInput
                style={styles.input}
                placeholder="081234567890"
                keyboardType="phone-pad"
                value={phone}
                onChangeText={setPhone}
                editable={!isLoading}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Password</Text>
              <TextInput
                style={styles.input}
                placeholder="Minimal 8 karakter"
                secureTextEntry
                value={password}
                onChangeText={setPassword}
                editable={!isLoading}
                autoCapitalize="none"
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Konfirmasi Password</Text>
              <TextInput
                style={styles.input}
                placeholder="Ketik ulang password"
                secureTextEntry
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                editable={!isLoading}
                autoCapitalize="none"
              />
            </View>

            {/* Seller Fields */}
            {role === 'SELLER' && (
              <>
                <View style={styles.divider} />
                <Text style={styles.sectionTitle}>Informasi Toko & Bank</Text>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Nama Toko</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="Masukkan nama toko"
                    value={storeName}
                    onChangeText={setStoreName}
                    editable={!isLoading}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Provinsi</Text>
                  <TouchableOpacity
                    style={styles.input}
                    onPress={() => setShowProvinceDropdown(!showProvinceDropdown)}
                    disabled={isLoading}
                  >
                    <Text style={province ? styles.inputText : styles.placeholder}>
                      {province || 'Pilih provinsi'}
                    </Text>
                  </TouchableOpacity>
                  {showProvinceDropdown && (
                    <View style={styles.dropdown}>
                      <ScrollView style={styles.dropdownScroll}>
                        {PROVINCES.map((prov) => (
                          <TouchableOpacity
                            key={prov}
                            style={styles.dropdownItem}
                            onPress={() => {
                              setProvince(prov);
                              setShowProvinceDropdown(false);
                            }}
                          >
                            <Text style={styles.dropdownItemText}>{prov}</Text>
                          </TouchableOpacity>
                        ))}
                      </ScrollView>
                    </View>
                  )}
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Nama Bank</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="Contoh: BCA, Mandiri, BNI"
                    value={bankName}
                    onChangeText={setBankName}
                    editable={!isLoading}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.label}>Nomor Rekening</Text>
                  <TextInput
                    style={styles.input}
                    placeholder="Masukkan nomor rekening"
                    keyboardType="number-pad"
                    value={bankAccount}
                    onChangeText={setBankAccount}
                    editable={!isLoading}
                  />
                </View>
              </>
            )}

            <TouchableOpacity
              style={[styles.button, isLoading && styles.buttonDisabled]}
              onPress={handleRegister}
              disabled={isLoading}
            >
              {isLoading ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.buttonText}>Daftar</Text>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.linkButton}
              onPress={() => router.back()}
              disabled={isLoading}
            >
              <Text style={styles.linkText}>
                Sudah punya akun? <Text style={styles.linkTextBold}>Masuk</Text>
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
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
  },
  content: {
    paddingHorizontal: 24,
    paddingVertical: 20,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#007AFF',
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
  },
  roleContainer: {
    marginBottom: 24,
  },
  roleButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  roleButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 16,
    borderWidth: 2,
    borderColor: '#ddd',
    borderRadius: 8,
    backgroundColor: '#f9f9f9',
  },
  roleButtonActive: {
    borderColor: '#007AFF',
    backgroundColor: '#EFF6FF',
  },
  roleButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
  },
  roleButtonTextActive: {
    color: '#007AFF',
  },
  form: {
    width: '100%',
  },
  inputGroup: {
    marginBottom: 16,
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
  inputText: {
    fontSize: 16,
    color: '#333',
  },
  placeholder: {
    fontSize: 16,
    color: '#999',
  },
  dropdown: {
    position: 'absolute',
    top: '100%',
    left: 0,
    right: 0,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    marginTop: 4,
    maxHeight: 200,
    zIndex: 1000,
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  dropdownScroll: {
    maxHeight: 200,
  },
  dropdownItem: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  dropdownItemText: {
    fontSize: 16,
    color: '#333',
  },
  divider: {
    height: 1,
    backgroundColor: '#e0e0e0',
    marginVertical: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#333',
    marginBottom: 16,
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
    marginBottom: 40,
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
