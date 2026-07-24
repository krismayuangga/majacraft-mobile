import React, { useRef } from 'react';
import { View, StyleSheet, ActivityIndicator, SafeAreaView } from 'react-native';
import WebView from 'react-native-webview';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, WEB_PAGES } from '../../constants/config';

/**
 * StudioScreen — Seller dashboard via WebView.
 * Seller menggunakan halaman /studio dari web app untuk kelola produk & pesanan.
 */
export default function StudioScreen() {
  const { token } = useAuth();
  const webViewRef = useRef<WebView>(null);

  const injectedJS = token ? `
    (function() { window.__mobileToken = '${token}'; })();
    true;
  ` : 'true;';

  return (
    <SafeAreaView style={styles.container}>
      <WebView
        ref={webViewRef}
        source={{ uri: `${API_BASE_URL}/studio` }}
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
  webview:   { flex: 1 },
  loading: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#0f0f0f',
  },
});
