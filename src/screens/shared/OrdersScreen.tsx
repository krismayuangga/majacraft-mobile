import React, { useRef } from 'react';
import {
  View, Text, StyleSheet, SafeAreaView,
  TouchableOpacity, ActivityIndicator,
} from 'react-native';
import WebView from 'react-native-webview';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, WEB_PAGES } from '../../constants/config';
import { RootStackParamList } from '../../navigation/types';

type Nav = NativeStackNavigationProp<RootStackParamList>;

/** Orders — tampil WebView jika login, prompt login jika belum */
export default function OrdersScreen() {
  const { token, isAuthenticated } = useAuth();
  const navigation = useNavigation<Nav>();

  // Tampil prompt login jika belum authenticated
  if (!isAuthenticated) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.guestContainer}>
          <Text style={styles.guestIcon}>📦</Text>
          <Text style={styles.guestTitle}>Pesanan Saya</Text>
          <Text style={styles.guestSubtitle}>
            Masuk untuk melihat riwayat dan status pesananmu
          </Text>
          <TouchableOpacity
            style={styles.loginBtn}
            onPress={() => navigation.navigate('Login')}
          >
            <Text style={styles.loginBtnText}>Masuk</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => navigation.navigate('Register')}>
            <Text style={styles.registerLink}>
              Belum punya akun? <Text style={styles.registerLinkAccent}>Daftar</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const injectedJS = `
    (function() { window.__mobileToken = '${token}'; })();
    true;
  `;

  return (
    <SafeAreaView style={styles.container}>
      <WebView
        source={{ uri: `${API_BASE_URL}${WEB_PAGES.ORDERS}` }}
        injectedJavaScriptBeforeContentLoaded={injectedJS}
        javaScriptEnabled
        domStorageEnabled
        sharedCookiesEnabled
        thirdPartyCookiesEnabled
        renderLoading={() => (
          <View style={styles.loading}>
            <ActivityIndicator size="large" color="#d97706" />
          </View>
        )}
        startInLoadingState
        style={styles.webview}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f0f' },
  webview: { flex: 1 },
  loading: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center', alignItems: 'center',
    backgroundColor: '#0f0f0f',
  },
  guestContainer: {
    flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32,
  },
  guestIcon:     { fontSize: 56, marginBottom: 16 },
  guestTitle:    { color: '#f5f5f0', fontSize: 22, fontWeight: '700', marginBottom: 12 },
  guestSubtitle: {
    color: '#6b7280', fontSize: 14, textAlign: 'center',
    lineHeight: 20, marginBottom: 32,
  },
  loginBtn: {
    backgroundColor: '#d97706', borderRadius: 12, width: '100%',
    padding: 16, alignItems: 'center', marginBottom: 16,
  },
  loginBtnText:       { color: '#fff', fontWeight: '700', fontSize: 16 },
  registerLink:       { color: '#6b7280', fontSize: 14 },
  registerLinkAccent: { color: '#d97706', fontWeight: '600' },
});
