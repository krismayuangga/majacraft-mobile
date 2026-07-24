import React from 'react';
import {
  View, Text, StyleSheet, SafeAreaView,
  ScrollView, TouchableOpacity, Image, Alert,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../../lib/AuthContext';
import { RootStackParamList } from '../../navigation/types';

type Nav = NativeStackNavigationProp<RootStackParamList>;

// ─── Guest view (belum login) ─────────────────────────────────────────────────

function GuestProfile() {
  const navigation = useNavigation<Nav>();
  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.guestContainer}>
        <View style={styles.guestAvatar}>
          <Text style={styles.guestAvatarText}>👤</Text>
        </View>
        <Text style={styles.guestTitle}>Belum Masuk</Text>
        <Text style={styles.guestSubtitle}>
          Masuk untuk melihat profil, riwayat pesanan, dan fitur lengkap MajaCraft
        </Text>
        <TouchableOpacity
          style={styles.guestLoginBtn}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.guestLoginText}>Masuk</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.guestRegisterBtn}
          onPress={() => navigation.navigate('Register')}
        >
          <Text style={styles.guestRegisterText}>Daftar Akun Baru</Text>
        </TouchableOpacity>
        <Text style={styles.guestNote}>
          Bergabung dan jual/beli kerajinan tangan Indonesia
        </Text>
      </View>
    </SafeAreaView>
  );
}

// ─── Authenticated profile ────────────────────────────────────────────────────

export default function ProfileScreen() {
  const { user, logout, isAuthenticated } = useAuth();

  if (!isAuthenticated) return <GuestProfile />;

  const handleLogout = () => {
    Alert.alert('Keluar', 'Yakin ingin keluar?', [
      { text: 'Batal', style: 'cancel' },
      {
        text: 'Keluar', style: 'destructive',
        onPress: async () => {
          await logout();
          // Navigation handled by AppNavigator
        },
      },
    ]);
  };

  const roleLabel = user?.role === 'SELLER' ? 'Seniman' :
                    user?.role === 'ADMIN'  ? 'Admin'   : 'Pembeli';

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.body}>
        {/* Avatar */}
        <View style={styles.avatarRow}>
          {user?.image
            ? <Image source={{ uri: user.image }} style={styles.avatar} />
            : (
              <View style={[styles.avatar, styles.avatarFallback]}>
                <Text style={styles.avatarLetter}>
                  {user?.name?.[0]?.toUpperCase() ?? '?'}
                </Text>
              </View>
            )
          }
          <View style={styles.avatarInfo}>
            <Text style={styles.name}>{user?.name ?? '-'}</Text>
            <Text style={styles.email}>{user?.email ?? '-'}</Text>
            <View style={styles.roleBadge}>
              <Text style={styles.roleText}>{roleLabel}</Text>
            </View>
          </View>
        </View>

        {/* KYC Status */}
        <View style={styles.card}>
          <Text style={styles.cardLabel}>Status Verifikasi</Text>
          <Text style={[
            styles.cardValue,
            { color: user?.kycStatus === 'VERIFIED' ? '#34d399' : '#fbbf24' },
          ]}>
            {user?.kycStatus === 'VERIFIED'   ? '✓ Terverifikasi' :
             user?.kycStatus === 'PENDING'    ? '⏳ Menunggu Verifikasi' :
             user?.kycStatus === 'REJECTED'   ? '✗ Ditolak' : '○ Belum Verifikasi'}
          </Text>
        </View>

        {/* Menu items */}
        {[
          { label: '🔔 Notifikasi', desc: 'Kelola preferensi notifikasi' },
          { label: '📍 Alamat', desc: 'Kelola alamat pengiriman' },
          { label: '🔒 Keamanan', desc: 'Ubah password & PIN' },
        ].map(item => (
          <TouchableOpacity key={item.label} style={styles.menuItem}>
            <View>
              <Text style={styles.menuLabel}>{item.label}</Text>
              <Text style={styles.menuDesc}>{item.desc}</Text>
            </View>
            <Text style={styles.menuArrow}>›</Text>
          </TouchableOpacity>
        ))}

        {/* Logout */}
        <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
          <Text style={styles.logoutText}>Keluar</Text>
        </TouchableOpacity>

        <Text style={styles.version}>MajaCraft v1.0.0</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#0f0f0f' },

  // Guest styles
  guestContainer: {
    flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32,
  },
  guestAvatar: {
    width: 96, height: 96, borderRadius: 48,
    backgroundColor: '#1c1c1e', alignItems: 'center', justifyContent: 'center',
    marginBottom: 20,
  },
  guestAvatarText: { fontSize: 40 },
  guestTitle: { color: '#f5f5f0', fontSize: 22, fontWeight: '700', marginBottom: 12 },
  guestSubtitle: {
    color: '#6b7280', fontSize: 14, textAlign: 'center',
    lineHeight: 20, marginBottom: 32,
  },
  guestLoginBtn: {
    backgroundColor: '#d97706', borderRadius: 12, width: '100%',
    padding: 16, alignItems: 'center', marginBottom: 12,
  },
  guestLoginText: { color: '#fff', fontWeight: '700', fontSize: 16 },
  guestRegisterBtn: {
    borderWidth: 1, borderColor: '#d97706', borderRadius: 12, width: '100%',
    padding: 16, alignItems: 'center', marginBottom: 24,
  },
  guestRegisterText: { color: '#d97706', fontWeight: '600', fontSize: 16 },
  guestNote: { color: '#374151', fontSize: 12, textAlign: 'center' },

  // Authenticated styles
  body: { padding: 20, paddingBottom: 40 },
  avatarRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 24 },
  avatar: { width: 72, height: 72, borderRadius: 36, marginRight: 16 },
  avatarFallback: {
    backgroundColor: '#92400e',
    alignItems: 'center', justifyContent: 'center',
  },
  avatarLetter: { color: '#fff', fontSize: 28, fontWeight: '700' },
  avatarInfo: { flex: 1 },
  name:  { color: '#f5f5f0', fontSize: 18, fontWeight: '700' },
  email: { color: '#9ca3af', fontSize: 13, marginTop: 2 },
  roleBadge: {
    alignSelf: 'flex-start', marginTop: 6,
    backgroundColor: '#92400e', borderRadius: 8,
    paddingHorizontal: 8, paddingVertical: 2,
  },
  roleText: { color: '#fbbf24', fontSize: 11, fontWeight: '600' },
  card: {
    backgroundColor: '#1c1c1e',
    borderRadius: 12, padding: 16,
    marginBottom: 12,
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
  },
  cardLabel: { color: '#9ca3af', fontSize: 13 },
  cardValue: { fontSize: 13, fontWeight: '600' },
  menuItem: {
    backgroundColor: '#1c1c1e',
    borderRadius: 12, padding: 16,
    marginBottom: 8,
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
  },
  menuLabel: { color: '#f5f5f0', fontSize: 14, fontWeight: '600' },
  menuDesc:  { color: '#6b7280', fontSize: 12, marginTop: 2 },
  menuArrow: { color: '#6b7280', fontSize: 20 },
  logoutBtn: {
    marginTop: 24,
    borderWidth: 1, borderColor: '#7f1d1d',
    borderRadius: 12, padding: 16,
    alignItems: 'center',
  },
  logoutText: { color: '#ef4444', fontWeight: '600', fontSize: 15 },
  version: { color: '#374151', textAlign: 'center', fontSize: 12, marginTop: 24 },
});
