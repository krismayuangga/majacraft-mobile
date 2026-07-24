import React, { useRef } from 'react';
import { View, StyleSheet, ActivityIndicator, SafeAreaView } from 'react-native';
import WebView from 'react-native-webview';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, WEB_PAGES } from '../../constants/config';

/** Orders — WebView ke /pesanan (buyer orders page) */
export default function OrdersScreen() {
  const { token } = useAuth();

  const injectedJS = token ? `
    (function() { window.__mobileToken = '${token}'; })();
    true;
  ` : 'true;';

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
});
