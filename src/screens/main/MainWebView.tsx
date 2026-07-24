import React, { useRef, useCallback, useEffect, useState } from 'react';
import {
  View, StyleSheet, StatusBar,
  ActivityIndicator, BackHandler,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import WebView, { WebViewNavigation } from 'react-native-webview';
import { useNavigation, useFocusEffect } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, API_ENDPOINTS, WEB_PAGES } from '../../constants/config';
import { RootStackParamList } from '../../navigation/types';

type Nav = NativeStackNavigationProp<RootStackParamList>;

/**
 * User Agent: format yang dikenali server untuk class body.in-mobile-app
 * Server checks: userAgent.includes('MajaCraftApp')
 */
const MOBILE_USER_AGENT =
  'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 MajaCraftApp/1.0';

/**
 * JS minimal yang di-inject sekali setelah halaman load.
 *
 * Strategi final:
 * - TAMBAHKAN "rn-app" class (jangan hapus "in-mobile-app" dari server)
 * - Server CSS sudah handle:
 *     in-mobile-app → hide footer, show chat/notification icons
 *     rn-app        → hide footer, show chat/notification icons
 * - Mobile CSS override: sembunyikan auth buttons (Masuk/Daftar)
 *     Login flow: user tap "Akun" di bottom nav → native Login modal
 * - TIDAK ada MutationObserver (penyebab bottom nav tidak bisa diklik)
 */
const INJECT_JS = `
  (function() {
    // Tambahkan class rn-app (biarkan in-mobile-app tetap ada)
    document.body.classList.add('rn-app');

    // Sembunyikan tombol Masuk/Daftar — user login via tab "Akun" di bottom nav
    if (!document.getElementById('rn-mobile-override')) {
      var style = document.createElement('style');
      style.id = 'rn-mobile-override';
      style.innerHTML =
        'body.rn-app [data-auth-buttons] { display: none !important; }';
      document.head.appendChild(style);
    }

    // Setup openNativeLogin (server script mungkin sudah inject, ini fallback)
    window.__isMobileApp = true;
    if (!window.__openNativeLogin) {
      window.__openNativeLogin = function(redirect) {
        if (window.ReactNativeWebView) {
          window.ReactNativeWebView.postMessage(
            JSON.stringify({ type: 'openLogin', redirect: redirect || '/' })
          );
        }
      };
    }
  })();
  true;
`;

/** Build URL awal: pakai webview-token endpoint jika sudah login */
function buildStartUrl(token: string | null): string {
  if (token) {
    return (
      `${API_BASE_URL}${API_ENDPOINTS.WEBVIEW_TOKEN}` +
      `?token=${encodeURIComponent(token)}` +
      `&redirect=${encodeURIComponent(WEB_PAGES.HOME)}`
    );
  }
  return `${API_BASE_URL}${WEB_PAGES.HOME}`;
}

export default function MainWebView() {
  const webViewRef    = useRef<WebView>(null);
  const navigation    = useNavigation<Nav>();
  const { token, logout, isAuthenticated } = useAuth();

  // Gunakan ref bukan state untuk canGoBack — menghindari re-render saat navigasi
  const canGoBackRef = useRef(false);

  // Selalu mulai dengan home page — aman untuk semua kasus
  const [webViewSource, setWebViewSource] = useState({
    uri: `${API_BASE_URL}/`,
  });

  // Simpan redirect URL saat openLogin dipanggil
  const pendingRedirectRef = useRef<string | null>(null);
  // Mulai dari FALSE → agar startup dengan stored token juga establish web session
  const prevAuthRef = useRef(false);
  // Flag untuk mencegah loop webview-token → hanya establish session SEKALI per sesi
  const sessionEstablishedRef = useRef(false);

  /**
   * Establish web session:
   * 1. Saat aktif login (wasLoggedIn false → true)
   * 2. Saat startup dengan stored token (prevAuthRef di-init false agar trigger ini)
   */
  useEffect(() => {
    const wasLoggedIn = prevAuthRef.current;
    prevAuthRef.current = isAuthenticated;

    if (!wasLoggedIn && isAuthenticated && token && !sessionEstablishedRef.current) {
      sessionEstablishedRef.current = true; // Tandai session sedang/sudah di-establish
      const redirect = pendingRedirectRef.current ?? WEB_PAGES.HOME;
      pendingRedirectRef.current = null;

      const tokenUrl =
        `${API_BASE_URL}${API_ENDPOINTS.WEBVIEW_TOKEN}` +
        `?token=${encodeURIComponent(token)}` +
        `&redirect=${encodeURIComponent(redirect)}`;

      setWebViewSource({ uri: tokenUrl });
    }

    // Reset flag saat logout agar bisa login lagi
    if (!isAuthenticated) {
      sessionEstablishedRef.current = false;
    }
  }, [isAuthenticated, token]);

  // Android back button — navigasi dalam WebView dulu
  useFocusEffect(
    useCallback(() => {
      const onBack = () => {
        if (canGoBackRef.current) {
          webViewRef.current?.goBack();
          return true;
        }
        return false;
      };
      const sub = BackHandler.addEventListener('hardwareBackPress', onBack);
      return () => sub.remove();
    }, []),
  );

  /**
   * Intercept URL navigasi WebView.
   * - needsLogin=1: jika sudah login natively → langsung establish web session
   *                 jika belum login → buka Login modal
   */
  const handleNavigationChange = useCallback((navState: WebViewNavigation) => {
    canGoBackRef.current = navState.canGoBack;
    const { url } = navState;
    if (!url) return;

    // Server middleware redirect ke /?needsLogin=1&redirect=<path>
    if (url.includes('needsLogin=1')) {
      try {
        const urlObj = new URL(url);
        const redirect = urlObj.searchParams.get('redirect') ?? '/';

        if (isAuthenticated && token) {
          // Sudah login natively → establish web session jika belum pernah
          if (!sessionEstablishedRef.current) {
            sessionEstablishedRef.current = true;
            const tokenUrl =
              `${API_BASE_URL}${API_ENDPOINTS.WEBVIEW_TOKEN}` +
              `?token=${encodeURIComponent(token)}` +
              `&redirect=${encodeURIComponent(redirect)}`;
            setWebViewSource({ uri: tokenUrl });
          }
          // Jika sessionEstablished tapi masih dapat needsLogin → web session expired
          // Biarkan halaman /?needsLogin=1 load dan buka Login modal via openNativeLogin message
        } else {
          // Belum login natively → buka Login modal
          pendingRedirectRef.current = redirect;
          navigation.navigate('Login', { redirect });
        }
      } catch {
        if (!isAuthenticated) {
          navigation.navigate('Login');
        }
      }
      return;
    }

    // Intercept halaman login web → buka native Login modal
    // Ini menangkap tap tombol "Masuk" di header web yang redirect ke /masuk
    if (url.endsWith('/masuk') || url.includes('/masuk?') ||
        (url.includes('/login') && !url.includes('webview-token'))) {
      webViewRef.current?.stopLoading();
      webViewRef.current?.goBack();
      navigation.navigate('Login');
      return;
    }

    // Intercept halaman register web → buka native Register modal
    if (url.endsWith('/daftar') || url.includes('/daftar?') ||
        url.includes('/register')) {
      webViewRef.current?.stopLoading();
      webViewRef.current?.goBack();
      navigation.navigate('Register');
      return;
    }
  }, [navigation, isAuthenticated, token, setWebViewSource]);

  /** Handle pesan dari WebView JavaScript (dikirim oleh server script) */
  const handleMessage = useCallback((event: any) => {
    try {
      const data = JSON.parse(event.nativeEvent.data);
      switch (data.type) {
        case 'openLogin':
          // Simpan redirect sebelum buka modal
          pendingRedirectRef.current = data.redirect ?? null;
          navigation.navigate('Login', { redirect: data.redirect });
          break;
        case 'openRegister':
          navigation.navigate('Register');
          break;
        case 'logout':
          logout();
          break;
        case 'pageReady':
          // WebView siap, tidak perlu aksi
          break;
      }
    } catch {
      // ignore non-JSON messages
    }
  }, [navigation, logout]);

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />
      <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
        <WebView
          ref={webViewRef}
          source={webViewSource}
          style={styles.webview}
          userAgent={MOBILE_USER_AGENT}
          onNavigationStateChange={handleNavigationChange}
          onMessage={handleMessage}
          injectedJavaScript={INJECT_JS}
          javaScriptEnabled
          domStorageEnabled
          sharedCookiesEnabled
          thirdPartyCookiesEnabled
          allowsInlineMediaPlayback
          mediaPlaybackRequiresUserAction={false}
          renderLoading={() => (
            <View style={styles.loading}>
              <ActivityIndicator size="large" color="#d97706" />
            </View>
          )}
          startInLoadingState={false}
          onError={(e) => {
            // Jika token URL gagal, fallback ke home page
            const { url } = e.nativeEvent;
            if (url && url.includes('webview-token')) {
              setWebViewSource({ uri: `${API_BASE_URL}/` });
            }
          }}
        />
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f0f' },
  safeArea:  { flex: 1, backgroundColor: '#0f0f0f' },
  webview:   { flex: 1 },
  loading: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#0f0f0f',
  },
});

