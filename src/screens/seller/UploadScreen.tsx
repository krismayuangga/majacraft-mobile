import React, { useState, useCallback } from 'react';
import {
  View, Text, StyleSheet, SafeAreaView,
  ScrollView, Image, TouchableOpacity,
  TextInput, Alert, ActivityIndicator,
  KeyboardAvoidingView, Platform,
} from 'react-native';
import { launchImageLibrary, launchCamera, Asset } from 'react-native-image-picker';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import api from '../../lib/api';
import { API_ENDPOINTS } from '../../constants/config';
import { Category } from '../../types';
import { MainTabParamList } from '../../navigation/types';

type Props = { navigation: BottomTabNavigationProp<MainTabParamList, 'Upload'> };

export default function UploadScreen({ navigation }: Props) {
  const [images,   setImages]   = useState<Asset[]>([]);
  const [name,     setName]     = useState('');
  const [desc,     setDesc]     = useState('');
  const [price,    setPrice]    = useState('');
  const [stock,    setStock]    = useState('1');
  const [weight,   setWeight]   = useState('');
  const [catId,    setCatId]    = useState('');
  const [catName,  setCatName]  = useState('Pilih Kategori');
  const [cats,     setCats]     = useState<Category[]>([]);
  const [showCats, setShowCats] = useState(false);
  const [uploading, setUploading] = useState(false);

  // Load categories
  React.useEffect(() => {
    api.get<Category[]>(API_ENDPOINTS.CATEGORIES)
      .then(r => setCats(r.data ?? []))
      .catch(() => {});
  }, []);

  const pickFromGallery = () => {
    launchImageLibrary({ mediaType: 'photo', selectionLimit: 5 - images.length }, (res) => {
      if (res.assets) setImages(prev => [...prev, ...res.assets!].slice(0, 5));
    });
  };

  const pickFromCamera = () => {
    launchCamera({ mediaType: 'photo', cameraType: 'back' }, (res) => {
      if (res.assets?.[0]) setImages(prev => [...prev, res.assets![0]].slice(0, 5));
    });
  };

  const removeImage = (idx: number) =>
    setImages(prev => prev.filter((_, i) => i !== idx));

  const handleSubmit = async () => {
    if (!name.trim())    return Alert.alert('Error', 'Nama produk wajib diisi');
    if (!desc.trim())    return Alert.alert('Error', 'Deskripsi wajib diisi');
    if (!price || +price <= 0) return Alert.alert('Error', 'Harga tidak valid');
    if (!catId)          return Alert.alert('Error', 'Pilih kategori terlebih dahulu');
    if (images.length === 0) return Alert.alert('Error', 'Minimal 1 foto produk');

    setUploading(true);
    try {
      // 1. Upload semua gambar
      const imageUrls: string[] = [];
      for (const img of images) {
        const fd = new FormData();
        fd.append('file', { uri: img.uri!, type: img.type ?? 'image/jpeg', name: img.fileName ?? 'photo.jpg' } as any);
        fd.append('folder', 'products');
        const uploadRes = await api.upload<{ url: string }>(API_ENDPOINTS.UPLOAD, fd);
        if (uploadRes.data?.url) imageUrls.push(uploadRes.data.url);
      }

      // 2. Buat produk
      const res = await api.post(API_ENDPOINTS.CREATE_PRODUCT, {
        name: name.trim(),
        description: desc.trim(),
        price: +price,
        stock: +stock || 1,
        weight: weight ? +weight : undefined,
        categoryId: catId,
        imageUrls,
      });

      if (res.data) {
        Alert.alert('Berhasil', 'Produk berhasil diupload! Menunggu moderasi admin.', [
          { text: 'OK', onPress: () => navigation.navigate('Studio' as any) },
        ]);
        // Reset form
        setImages([]); setName(''); setDesc(''); setPrice('');
        setStock('1'); setWeight(''); setCatId(''); setCatName('Pilih Kategori');
      } else {
        Alert.alert('Gagal', res.message ?? 'Upload gagal');
      }
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Upload Produk</Text>
        </View>

        <ScrollView contentContainerStyle={styles.body} keyboardShouldPersistTaps="handled">
          {/* Photo picker */}
          <Text style={styles.label}>Foto Produk * (maks 5)</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.photoRow}>
            {images.map((img, idx) => (
              <View key={idx} style={styles.thumb}>
                <Image source={{ uri: img.uri }} style={styles.thumbImg} />
                <TouchableOpacity style={styles.thumbRemove} onPress={() => removeImage(idx)}>
                  <Text style={styles.thumbRemoveText}>✕</Text>
                </TouchableOpacity>
              </View>
            ))}
            {images.length < 5 && (
              <View style={styles.photoActions}>
                <TouchableOpacity style={styles.addPhoto} onPress={pickFromCamera}>
                  <Text style={styles.addPhotoIcon}>📷</Text>
                  <Text style={styles.addPhotoLabel}>Kamera</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.addPhoto} onPress={pickFromGallery}>
                  <Text style={styles.addPhotoIcon}>🖼️</Text>
                  <Text style={styles.addPhotoLabel}>Galeri</Text>
                </TouchableOpacity>
              </View>
            )}
          </ScrollView>

          {/* Fields */}
          <Text style={styles.label}>Nama Produk *</Text>
          <TextInput style={styles.input} value={name} onChangeText={setName} placeholder="Nama produk..." placeholderTextColor="#6b7280" />

          <Text style={styles.label}>Deskripsi *</Text>
          <TextInput
            style={[styles.input, { height: 100, textAlignVertical: 'top' }]}
            value={desc} onChangeText={setDesc}
            placeholder="Deskripsikan produk Anda..." placeholderTextColor="#6b7280"
            multiline numberOfLines={4}
          />

          <View style={styles.row}>
            <View style={styles.half}>
              <Text style={styles.label}>Harga (Rp) *</Text>
              <TextInput style={styles.input} value={price} onChangeText={setPrice} placeholder="50000" placeholderTextColor="#6b7280" keyboardType="numeric" />
            </View>
            <View style={styles.half}>
              <Text style={styles.label}>Stok</Text>
              <TextInput style={styles.input} value={stock} onChangeText={setStock} placeholder="1" placeholderTextColor="#6b7280" keyboardType="numeric" />
            </View>
          </View>

          <View style={styles.row}>
            <View style={styles.half}>
              <Text style={styles.label}>Berat (gram)</Text>
              <TextInput style={styles.input} value={weight} onChangeText={setWeight} placeholder="500" placeholderTextColor="#6b7280" keyboardType="numeric" />
            </View>
          </View>

          <Text style={styles.label}>Kategori *</Text>
          <TouchableOpacity style={styles.input} onPress={() => setShowCats(!showCats)}>
            <Text style={{ color: catId ? '#f5f5f0' : '#6b7280' }}>{catName}</Text>
          </TouchableOpacity>
          {showCats && (
            <View style={styles.catList}>
              {cats.map(c => (
                <TouchableOpacity
                  key={c.id}
                  style={[styles.catItem, catId === c.id && styles.catItemActive]}
                  onPress={() => { setCatId(c.id); setCatName(c.name); setShowCats(false); }}
                >
                  <Text style={[styles.catText, catId === c.id && styles.catTextActive]}>
                    {c.icon} {c.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          <TouchableOpacity
            style={[styles.submitBtn, uploading && { opacity: 0.6 }]}
            onPress={handleSubmit}
            disabled={uploading}
          >
            {uploading
              ? <ActivityIndicator color="#fff" />
              : <Text style={styles.submitText}>Upload Produk</Text>
            }
          </TouchableOpacity>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe:   { flex: 1, backgroundColor: '#0f0f0f' },
  flex:   { flex: 1 },
  header: { padding: 16, borderBottomWidth: 1, borderBottomColor: '#1f2937' },
  title:  { color: '#f5f5f0', fontSize: 18, fontWeight: '700' },
  body:   { padding: 16, paddingBottom: 32 },
  label:  { color: '#9ca3af', fontSize: 12, fontWeight: '600', marginBottom: 6, marginTop: 14 },
  input: {
    backgroundColor: '#1c1c1e',
    borderWidth: 1, borderColor: '#374151',
    borderRadius: 10, padding: 12,
    color: '#f5f5f0', fontSize: 14,
  },
  row:   { flexDirection: 'row', gap: 12 },
  half:  { flex: 1 },
  photoRow:  { marginBottom: 8 },
  photoActions: { flexDirection: 'row', gap: 8 },
  addPhoto: {
    width: 80, height: 80,
    backgroundColor: '#1c1c1e', borderWidth: 1, borderColor: '#374151',
    borderRadius: 10, alignItems: 'center', justifyContent: 'center', marginRight: 8,
  },
  addPhotoIcon:  { fontSize: 20 },
  addPhotoLabel: { color: '#6b7280', fontSize: 10, marginTop: 4 },
  thumb: { width: 80, height: 80, borderRadius: 10, marginRight: 8, position: 'relative' },
  thumbImg: { width: 80, height: 80, borderRadius: 10 },
  thumbRemove: {
    position: 'absolute', top: -6, right: -6,
    width: 20, height: 20, borderRadius: 10,
    backgroundColor: '#ef4444', alignItems: 'center', justifyContent: 'center',
  },
  thumbRemoveText: { color: '#fff', fontSize: 10, fontWeight: '700' },
  catList: {
    backgroundColor: '#1c1c1e', borderWidth: 1, borderColor: '#374151',
    borderRadius: 10, marginTop: 4, overflow: 'hidden',
  },
  catItem: { padding: 12, borderBottomWidth: 1, borderBottomColor: '#374151' },
  catItemActive: { backgroundColor: '#92400e' },
  catText: { color: '#d1d5db', fontSize: 14 },
  catTextActive: { color: '#fbbf24', fontWeight: '600' },
  submitBtn: {
    backgroundColor: '#d97706', borderRadius: 12,
    padding: 16, alignItems: 'center', marginTop: 24,
  },
  submitText: { color: '#fff', fontWeight: '700', fontSize: 16 },
});
