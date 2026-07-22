import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Image,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useImagePicker } from '../../hooks/useImagePicker';
import api from '../../lib/api';
import { createImageFormData } from '../../lib/upload';
import { API_ENDPOINTS, UPLOAD_CONFIG } from '../../constants/config';

const CATEGORIES = [
  'Kerajinan Tangan',
  'Aksesoris',
  'Dekorasi',
  'Fashion',
  'Furniture',
  'Mainan',
  'Alat Tulis',
  'Lainnya',
];

export default function Upload() {
  const router = useRouter();
  const { images, isLoading: isPickingImage, addImageFromCamera, addImageFromGallery, addMultipleImages, removeImage } = useImagePicker(UPLOAD_CONFIG.MAX_IMAGES_PER_PRODUCT);
  
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [price, setPrice] = useState('');
  const [stock, setStock] = useState('');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const handleSubmit = async () => {
    // Validation
    if (!name.trim()) {
      Alert.alert('Error', 'Nama produk wajib diisi');
      return;
    }
    if (!description.trim()) {
      Alert.alert('Error', 'Deskripsi produk wajib diisi');
      return;
    }
    if (!price.trim() || isNaN(Number(price)) || Number(price) <= 0) {
      Alert.alert('Error', 'Harga harus berupa angka positif');
      return;
    }
    if (!stock.trim() || isNaN(Number(stock)) || Number(stock) < 0) {
      Alert.alert('Error', 'Stok harus berupa angka 0 atau lebih');
      return;
    }
    if (images.length === 0) {
      Alert.alert('Error', 'Minimal 1 foto produk harus ditambahkan');
      return;
    }

    setIsUploading(true);
    setUploadProgress(0);

    try {
      // Upload images first
      const imageUrls: string[] = [];
      for (let i = 0; i < images.length; i++) {
        const formData = await createImageFormData(images[i], 'file', 'products');
        
        const response = await api.upload(
          API_ENDPOINTS.UPLOAD,
          formData,
          (progressEvent) => {
            if (progressEvent.total) {
              const percentCompleted = Math.round(
                ((i + progressEvent.loaded / progressEvent.total) / images.length) * 100
              );
              setUploadProgress(percentCompleted);
            }
          }
        );

        if (response.success && response.data?.url) {
          imageUrls.push(response.data.url);
        } else {
          throw new Error('Failed to upload image');
        }
      }

      // Create product
      const productData = {
        name: name.trim(),
        description: description.trim(),
        price: Number(price),
        stock: Number(stock),
        category: category,
        images: imageUrls,
      };

      const result = await api.post(API_ENDPOINTS.CREATE_PRODUCT, productData);

      if (result.success) {
        Alert.alert(
          'Berhasil!',
          'Produk berhasil ditambahkan',
          [
            {
              text: 'OK',
              onPress: () => {
                // Reset form
                setName('');
                setDescription('');
                setPrice('');
                setStock('');
                setCategory(CATEGORIES[0]);
                // Clear images handled by hook
                router.push('/(tabs)/products');
              },
            },
          ]
        );
      } else {
        Alert.alert('Error', result.message || 'Gagal menambahkan produk');
      }
    } catch (error: any) {
      console.error('Upload error:', error);
      Alert.alert('Error', error.message || 'Terjadi kesalahan saat upload produk');
    } finally {
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  const renderImagePicker = () => (
    <View style={styles.imageSection}>
      <Text style={styles.sectionLabel}>Foto Produk *</Text>
      <Text style={styles.sectionHint}>
        {images.length}/{UPLOAD_CONFIG.MAX_IMAGES_PER_PRODUCT} foto (Max 5MB per foto)
      </Text>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.imageList}>
        {images.map((uri, index) => (
          <View key={index} style={styles.imageItem}>
            <Image source={{ uri }} style={styles.image} />
            <TouchableOpacity
              style={styles.removeImageButton}
              onPress={() => removeImage(index)}
            >
              <Ionicons name="close-circle" size={24} color="#ff3b30" />
            </TouchableOpacity>
          </View>
        ))}

        {images.length < UPLOAD_CONFIG.MAX_IMAGES_PER_PRODUCT && (
          <View style={styles.addImageButtons}>
            <TouchableOpacity
              style={styles.addImageButton}
              onPress={addImageFromCamera}
              disabled={isPickingImage}
            >
              <Ionicons name="camera" size={32} color="#007AFF" />
              <Text style={styles.addImageText}>Kamera</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.addImageButton}
              onPress={addMultipleImages}
              disabled={isPickingImage}
            >
              <Ionicons name="images" size={32} color="#007AFF" />
              <Text style={styles.addImageText}>Galeri</Text>
            </TouchableOpacity>
          </View>
        )}
      </ScrollView>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView style={styles.scrollView} keyboardShouldPersistTaps="handled">
          <View style={styles.header}>
            <Text style={styles.title}>Upload Produk Baru</Text>
            <Text style={styles.subtitle}>Isi detail produk yang akan dijual</Text>
          </View>

          {renderImagePicker()}

          <View style={styles.form}>
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Nama Produk *</Text>
              <TextInput
                style={styles.input}
                placeholder="Contoh: Tas Rajut Handmade"
                value={name}
                onChangeText={setName}
                editable={!isUploading}
              />
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Deskripsi *</Text>
              <TextInput
                style={[styles.input, styles.textArea]}
                placeholder="Jelaskan detail produk, bahan, ukuran, dll"
                value={description}
                onChangeText={setDescription}
                multiline
                numberOfLines={4}
                textAlignVertical="top"
                editable={!isUploading}
              />
            </View>

            <View style={styles.row}>
              <View style={[styles.inputGroup, styles.halfWidth]}>
                <Text style={styles.label}>Harga (Rp) *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="50000"
                  value={price}
                  onChangeText={setPrice}
                  keyboardType="numeric"
                  editable={!isUploading}
                />
              </View>

              <View style={[styles.inputGroup, styles.halfWidth]}>
                <Text style={styles.label}>Stok *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="10"
                  value={stock}
                  onChangeText={setStock}
                  keyboardType="numeric"
                  editable={!isUploading}
                />
              </View>
            </View>

            <View style={styles.inputGroup}>
              <Text style={styles.label}>Kategori *</Text>
              <TouchableOpacity
                style={styles.pickerButton}
                onPress={() => setShowCategoryPicker(!showCategoryPicker)}
                disabled={isUploading}
              >
                <Text style={styles.pickerText}>{category}</Text>
                <Ionicons
                  name={showCategoryPicker ? 'chevron-up' : 'chevron-down'}
                  size={20}
                  color="#666"
                />
              </TouchableOpacity>

              {showCategoryPicker && (
                <View style={styles.pickerList}>
                  {CATEGORIES.map((cat) => (
                    <TouchableOpacity
                      key={cat}
                      style={[
                        styles.pickerItem,
                        category === cat && styles.pickerItemSelected,
                      ]}
                      onPress={() => {
                        setCategory(cat);
                        setShowCategoryPicker(false);
                      }}
                    >
                      <Text
                        style={[
                          styles.pickerItemText,
                          category === cat && styles.pickerItemTextSelected,
                        ]}
                      >
                        {cat}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              )}
            </View>

            <TouchableOpacity
              style={[styles.submitButton, isUploading && styles.submitButtonDisabled]}
              onPress={handleSubmit}
              disabled={isUploading || isPickingImage}
            >
              {isUploading ? (
                <View style={styles.uploadingContainer}>
                  <ActivityIndicator color="#fff" />
                  <Text style={styles.submitButtonText}>
                    Uploading... {uploadProgress}%
                  </Text>
                </View>
              ) : (
                <Text style={styles.submitButtonText}>Upload Produk</Text>
              )}
            </TouchableOpacity>
          </View>
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
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#666',
  },
  imageSection: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  sectionLabel: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 4,
  },
  sectionHint: {
    fontSize: 12,
    color: '#999',
    marginBottom: 12,
  },
  imageList: {
    flexDirection: 'row',
  },
  imageItem: {
    marginRight: 12,
    position: 'relative',
  },
  image: {
    width: 100,
    height: 100,
    borderRadius: 8,
    backgroundColor: '#f5f5f5',
  },
  removeImageButton: {
    position: 'absolute',
    top: -8,
    right: -8,
    backgroundColor: '#fff',
    borderRadius: 12,
  },
  addImageButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  addImageButton: {
    width: 100,
    height: 100,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#007AFF',
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  addImageText: {
    fontSize: 12,
    color: '#007AFF',
    marginTop: 4,
  },
  form: {
    padding: 20,
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
  textArea: {
    height: 100,
    paddingTop: 12,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  halfWidth: {
    flex: 1,
  },
  pickerButton: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#f9f9f9',
  },
  pickerText: {
    fontSize: 16,
    color: '#333',
  },
  pickerList: {
    marginTop: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    backgroundColor: '#fff',
  },
  pickerItem: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  pickerItemSelected: {
    backgroundColor: '#e8f4ff',
  },
  pickerItemText: {
    fontSize: 16,
    color: '#333',
  },
  pickerItemTextSelected: {
    color: '#007AFF',
    fontWeight: '600',
  },
  submitButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
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
  uploadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
});
