import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView reusable untuk halaman informasi / bantuan dari website
class InfoWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const InfoWebViewScreen({super.key, required this.title, required this.url});

  @override
  State<InfoWebViewScreen> createState() => _InfoWebViewScreenState();
}

class _InfoWebViewScreenState extends State<InfoWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  // JavaScript yang diinjeksi untuk menyembunyikan chrome website (navbar, footer, dll.)
  // Menggunakan MutationObserver agar bekerja meski Next.js hydrate setelah DOMContentLoaded
  static const String _hideChromeCss = r'''
    (function() {
      function hideChrome() {
        // Sembunyikan berdasarkan HTML tags standar
        var selectors = [
          'nav', 'header', 'footer',
          // Tailwind sticky/fixed top bar
          '[class*="sticky"]', '[class*="fixed"]',
          // Bottom navigation / mobile bottom bar  
          '[class*="bottom"]',
          // Elemen dengan z-index tinggi yang biasanya navbar
        ].join(',');

        // Juga cari elemen nav/header/footer langsung
        ['nav','header','footer'].forEach(function(tag) {
          document.querySelectorAll(tag).forEach(function(el) {
            el.style.setProperty('display', 'none', 'important');
          });
        });

        // Cari fixed/sticky elemen di atas/bawah halaman
        document.querySelectorAll('[class]').forEach(function(el) {
          var cls = el.className || '';
          if (typeof cls !== 'string') return;
          // Tailwind sticky top classes
          if (cls.includes('sticky') && (cls.includes('top') || cls.includes('z-'))) {
            el.style.setProperty('display', 'none', 'important');
          }
          // Tailwind fixed classes
          if (cls.includes('fixed') && (cls.includes('top') || cls.includes('bottom'))) {
            el.style.setProperty('display', 'none', 'important');
          }
        });

        // Hapus padding-top body yang biasanya untuk navbar
        document.body.style.setProperty('padding-top', '0', 'important');
        document.body.style.setProperty('margin-top', '0', 'important');
        if (document.documentElement) {
          document.documentElement.style.setProperty('scroll-padding-top', '0', 'important');
        }
      }

      // Jalankan langsung
      hideChrome();

      // Jalankan lagi setelah delay (Next.js hydration)
      setTimeout(hideChrome, 500);
      setTimeout(hideChrome, 1500);

      // MutationObserver untuk menangkap elemen yang ditambahkan setelah load
      var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          if (mutation.addedNodes.length > 0) {
            hideChrome();
          }
        });
      });
      observer.observe(document.body, { childList: true, subtree: true });

      // Berhenti observe setelah 10 detik agar tidak boros performa
      setTimeout(function() { observer.disconnect(); }, 10000);
    })();
  ''';

  void _injectHideChrome() {
    _controller.runJavaScript(_hideChromeCss);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // Injeksi CSS untuk sembunyikan navbar/footer setelah halaman load
            _injectHideChrome();
          },
          onProgress: (p) => setState(() => _loadingProgress = p),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFFFBBF24),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
