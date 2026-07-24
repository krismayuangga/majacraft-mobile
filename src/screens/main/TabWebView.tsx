import React, { useRef, useCallback, useEffect, useState } from 'react';
import { View, StyleSheet, BackHandler } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import WebView, { WebViewNavigation } from 'react-native-webview';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useAuth } from '../../lib/AuthContext';
import { API_BASE_URL, API_ENDPOINTS } from '../../constants/config';
import { RootStackParamList } from '../../navigation/types';

type Nav = NativeStackNavigationProp<RootStackParamList>;

interface Props {
  url: string;
  protected?: boolean;
}

const MOBILE_USER_AGENT =
  'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 MajaCraftApp/1.0';

const PRE_CSS_JS = `
  (function() {
    var s = document.createElement('style');
    s.id = 'rn-pre-css';
    s.textContent = '[data-web-bottom-nav]{display:none!important}footer,[data-footer]{display:none!important}[data-auth-buttons]{display:none!important}';
    (document.head || document.documentElement).appendChild(s);
  })();
  true;
`;

const INJECT_JS = `
  (function() {
    document.body.classList.add('rn-app');
    function hideWebNav() {
      document.querySelectorAll('[data-web-bottom-nav]').forEach(function(el) {
        el.style.setProperty('display', 'none', 'important');
      });
      document.querySelectorAll('footer, [data-footer]').forEach(function(el) {
        el.style.setProperty('display', 'none', 'important');
      });
    }
    hideWebNav();
    window.__isMobileApp = true;
    if (!window.__openNativeLogin) {
      window.__openNativeLogin = function(redirect) {
        if (window.ReactNativeWebView) {
          window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'openLogin', redirect: redirect || '/' }));
        }
      };
    }
  })();
  true;
`;

export default function TabWebView({ url, protected: isProtected }: Props) {
  const webViewRef   = useRef<WebView>(null);
  const navigation   = useNavigation<Nav>();
  const { token, isAuthenticated } = useAuth();
  const canGoBackRef = useRef(false);
  const sessionDoneRef = useRef(false);

  const buildTokenUrl = (redirect: string) =>
    `${API_BASE_URL}${API_ENDPOINTS.WEBVIEW_TOKEN}` +
    `?token=${encodeURIComponent(token!)}` +
    `&redirect=${encodeURIComponent(redirect)}`;

  const [source, setSource] = useState(() => ({
    uri: `${API_BASE_URL}${url}`,
  }));

  /**
   * Establish web session menggunakan fetch() dalam WebView context.
   * Lebih reliable dari redirect di Android WebView karena:
   * - Cookies dari fetch response langsung masuk ke cookie jar browser
   * - window.location.replace setelah fetch memastikan cookie sudah tersimpan
   * - Menghindari race condition antara cookie storage dan redirect
   */
  const establishSession = useCallback((redirect: string) => {
    if (!token || !webViewRef.current) return;
    const tokenUrl = buildTokenUrl(redirect);
    const finalUrl = `${API_BASE_URL}${redirect}`;
    const js = [
      '(function() {',
      `  var tokenUrl = '${tokenUrl}';`,
      `  var finalUrl = '${finalUrl}';`,
      '  fetch(tokenUrl, { credentials: "include" })',
      '    .then(function() { window.location.replace(finalUrl); })',
      '    .catch(function() { window.location.replace(finalUrl); });',
      '})();',
      'true;',
    ].join('\n');
    webViewRef.current.injectJavaScript(js);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  useEffect(() => {
    if (isAuthenticated && token && !sessionDoneRef.current) {
      sessionDoneRef.current = true;
      // Delay kecil untuk pastikan WebView sudah siap menerima injectJavaScript
      const timer = setTimeout(() => {
        establishSession(url);
      }, 300);
      return () => clearTimeout(timer);
    }
    if (!isAuthenticated) {
      sessionDoneRef.current = false;
      setSource({ uri: `${API_BASE_URL}${url}` });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, token]);

  useFocusEffect(
    useCallback(() => {
      // Back button handler — Login navigation sudah dihandle di AppNavigator tabPress listener
      if (isProtected && !isAuthenticated) {
        // Tidak perlu navigate di sini karena tabPress listener sudah handle ini
        // Hanya setup back button
      }
      const sub = BackHandler.addEventListener('hardwareBackPress', () => {
        if (canGoBackRef.current) { webViewRef.current?.goBack(); return true; }
        return false;
      });
      return () => sub.remove();
    }, [isAuthenticated, isProtected]),
  );

  const handleNavigationChange = useCallback((navState: WebViewNavigation) => {
    canGoBackRef.current = navState.canGoBack;
    const { url: navUrl } = navState;
    if (!navUrl) return;

    if (navUrl.includes('needsLogin=1')) {
      if (isAuthenticated && token) {
        // Sudah login natively → establish/re-establish web session
        // Reset sessionDoneRef agar bisa retry jika sebelumnya gagal
        sessionDoneRef.current = false;
        try {
          const redirect = new URL(navUrl).searchParams.get('redirect') ?? url;
          setTimeout(() => {
            sessionDoneRef.current = true;
            establishSession(redirect);
          }, 200);
        } catch { /* ignore */ }
      } else if (!isAuthenticated) {
        // Belum login → intercept sudah di tabPress, tapi jaga-jaga jika lolos
        navigation.getParent<any>()?.navigate('Login', { redirect: url });
      }
      return;
    }

    if (navUrl.endsWith('/masuk') || navUrl.includes('/masuk?') ||
        (navUrl.includes('/login') && !navUrl.includes('webview-token'))) {
      webViewRef.current?.stopLoading();
      webViewRef.current?.goBack();
      navigation.navigate('Login');
      return;
    }
    if (navUrl.endsWith('/daftar') || navUrl.includes('/daftar?') || navUrl.includes('/register')) {
      webViewRef.current?.stopLoading();
      webViewRef.current?.goBack();
      navigation.navigate('Register');
      return;
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, token, url, navigation]);

  const handleMessage = useCallback((event: any) => {
    try {
      const data = JSON.parse(event.nativeEvent.data);
      if (data.type === 'openLogin') {
        if (!isAuthenticated) {
          // Belum login natively → buka Login modal
          navigation.navigate('Login', { redirect: data.redirect });
        } else if (token && !sessionDoneRef.current) {
          // Sudah login natively tapi web session belum ada → re-establish
          sessionDoneRef.current = true;
          establishSession(data.redirect ?? url);
        }
        // Jika sessionDone → abaikan (session sudah dicoba, mungkin sedang proses)
      } else if (data.type === 'openRegister') {
        navigation.navigate('Register');
      }
    } catch { /* ignore */ }
  }, [navigation]);

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <WebView
        ref={webViewRef}
        source={source}
        style={styles.webview}
        userAgent={MOBILE_USER_AGENT}
        injectedJavaScriptBeforeContentLoaded={PRE_CSS_JS}
        injectedJavaScript={INJECT_JS}
        onNavigationStateChange={handleNavigationChange}
        onMessage={handleMessage}
        javaScriptEnabled
        domStorageEnabled
        sharedCookiesEnabled
        thirdPartyCookiesEnabled
        allowsInlineMediaPlayback
        mediaPlaybackRequiresUserAction={false}
        onError={(e) => {
          if (e.nativeEvent.url?.includes('webview-token')) {
            sessionDoneRef.current = false;
            setSource({ uri: `${API_BASE_URL}${url}` });
          }
        }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#0f0f0f' },
  webview:   { flex: 1 },
});
