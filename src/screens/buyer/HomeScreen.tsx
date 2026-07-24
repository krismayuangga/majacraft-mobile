import React, { useRef, useEffect, useState } from 'react';
import {
  View, StyleSheet, ActivityIndicator, SafeAreaView,
} from 'react-native';
import WebView, { WebViewNavigation } from 'react-native-webview';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, API_ENDPOINTS, WEB_PAGES } from '../../constants/config';
import { MainTabParamList } from '../../navigation/types';

type Props = { navigation: BottomTabNavigationProp<MainTabParamList, 'Home'> };

/**
 * HomeScreen — Buyer-facing WebView.
 *
 * Auth sync: JWT mobile ditukar ke NextAuth session cookie via
 * /api/auth/mobile/webview-token sehingga user otomatis login di web app.
 */
export default function HomeScreen({ navigation }: Props) {
  const { token } = useAuth();
  const webViewRef = useRef<WebView>(null);
  const [startUrl, setStartUrl] = useState<string | null>(null);

  useEffect(() => {
    if (token) {
      // Muat via webview-token agar session NextAuth tercipta
      const loginUrl =
        `${API_BASE_URL}${API_ENDPOINTS.WEBVIEW_TOKEN}` +
        `?token=${encodeURIComponent(token)}` +
        `&redirect=${encodeURIComponent(WEB_PAGES.HOME)}`;
      setStartUrl(loginUrl);
    } else {
      setStartUrl(`${API_BASE_URL}${WEB_PAGES.HOME}`);
    }
  }, [token]);

  const handleNavChange = (navState: WebViewNavigation) => {
    const { url } = navState;
    if (url.includes('/studio/upload') || url.includes('/buka-toko')) {
      webViewRef.current?.stopLoading();
      navigation.navigate('Upload' as any);
    }
  };

  if (!startUrl) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator size="large" color="#d97706" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <WebView
        ref={webViewRef}
        source={{ uri: startUrl }}
        onNavigationStateChange={handleNavChange}
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
