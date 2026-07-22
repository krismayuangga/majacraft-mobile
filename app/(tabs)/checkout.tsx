import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { CreateOrderInput } from '../../types';

export default function Checkout() {
  const router = useRouter();
  const params = useLocalSearchParams<{
    productId: string;
    productName: string;
    price: string;
    maxStock: string;
  }>();

  const [quantity, setQuantity] = useState('1');
  const [shippingAddress, setShippingAddress] = useState('');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const totalPrice = Number(params.price || 0) * Number(quantity || 1);

  const handleSubmit = async () => {
    // Validation
    if (!quantity.trim() || isNaN(Number(quantity)) || Number(quantity) <= 0) {
      Alert.alert('Error', 'Jumlah harus berupa angka positif');
      return;
    }

    if (Number(quantity) > Number(params.maxStock)) {
      Alert.alert('Error', `Stok tersedia hanya ${params.maxStock}`);
      return;
    }

    if (!shippingAddress.trim()) {
      Alert.alert('Error', 'Alamat pengiriman wajib diisi');
      return;
    }

    setIsSubmitting(true);

    try {
      const orderData: CreateOrderInput = {
        productId: params.productId,
        quantity: Number(quantity),
        shippingAddress: shippingAddress.trim(),
        notes: notes.trim() || undefined,
      };

      const result = await api.post(API_ENDPOINTS.CREATE_ORDER, orderData);

      if (result.success) {
        Alert.alert(
          'Pesanan Berhasil!',
          'Pesanan Anda telah dibuat. Silakan lakukan pembayaran.',
          [
            {
              text: 'Lihat Pesanan',
              onPress: () => router.replace('/(tabs)/orders'),
            },
          ]
        );
      } else {
        Alert.alert('Error', result.message || 'Gagal membuat pesanan');
      }
    } catch (error: any) {
      console.error('Checkout error:', error);
      Alert.alert('Error', error.message || 'Terjadi kesalahan saat checkout');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView style={styles.scrollView} keyboardShouldPersistTaps="handled">
          <View style={styles.header}>
            <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
              <Text style={styles.backText}>← Kembali</Text>
            </TouchableOpacity>
            <Text style={styles.title}>Checkout</Text>
          </View>

          {/* Product Summary */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Detail Produk</Text>
            <View style={styles.productSummary}>
              <Text style={styles.productName}>{params.productName}</Text>
              <Text style={styles.productPrice}>
                Rp {Number(params.price || 0).toLocaleString('id-ID')}
              </Text>
              <Text style={styles.productStock}>Stok: {params.maxStock}</Text>
            </View>
          </View>

          {/* Order Form */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Detail Pesanan</Text>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Jumlah *</Text>
              <TextInput
                style={styles.input}
                placeholder="1"
                value={quantity}
                onChangeText={setQuantity}
                keyboardType="numeric"
                editable={!isSubmitting}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Alamat Pengiriman *</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Jl. Contoh No. 123, Jakarta"
                value={shippingAddress}
                onChangeText={setShippingAddress}
                multiline
                numberOfLines={3}
                textAlignVertical="top"
                editable={!isSubmitting}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Catatan (Opsional)</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Tambahkan catatan untuk penjual..."
                value={notes}
                onChangeText={setNotes}
                multiline
                numberOfLines={2}
                textAlignVertical="top"
                editable={!isSubmitting}
              />
            </View>
          </View>

          {/* Order Summary */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Ringkasan Pesanan</Text>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Subtotal</Text>
              <Text style={styles.summaryValue}>
                Rp {totalPrice.toLocaleString('id-ID')}
              </Text>
            </View>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Ongkir</Text>
              <Text style={styles.summaryValue}>Rp 0</Text>
            </View>
            <View style={[styles.summaryRow, styles.totalRow]}>
              <Text style={styles.totalLabel}>Total</Text>
              <Text style={styles.totalValue}>
                Rp {totalPrice.toLocaleString('id-ID')}
              </Text>
            </View>
          </View>

          <TouchableOpacity
            style={[styles.submitButton, isSubmitting && styles.submitButtonDisabled]}
            onPress={handleSubmit}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.submitButtonText}>Buat Pesanan</Text>
            )}
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  keyboardView: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    padding: 20,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  backButton: {
    marginBottom: 12,
  },
  backText: {
    fontSize: 16,
    color: '#007AFF',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
  },
  section: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
  },
  productSummary: {
    backgroundColor: '#f9f9f9',
    padding: 16,
    borderRadius: 8,
  },
  productName: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  productPrice: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 4,
  },
  productStock: {
    fontSize: 14,
    color: '#666',
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
  textArea: {
    height: 80,
    paddingTop: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  summaryLabel: {
    fontSize: 14,
    color: '#666',
  },
  summaryValue: {
    fontSize: 14,
    color: '#333',
  },
  totalRow: {
    borderTopWidth: 1,
    borderTopColor: '#ddd',
    marginTop: 8,
    paddingTop: 16,
  },
  totalLabel: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  totalValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#007AFF',
  },
  submitButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    margin: 20,
    marginTop: 10,
  },
  submitButtonDisabled: {
    opacity: 0.6,
  },
  submitButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
