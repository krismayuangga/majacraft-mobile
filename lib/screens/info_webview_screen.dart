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

  // CSS yang diinjeksi untuk menyembunyikan navbar/footer/bottom-nav website
  static const String _hideChromeCss = '''
    (function() {
      var style = document.createElement('style');
      style.innerHTML = `
        /* Sembunyikan navbar/header website */
        nav,
        header,
        .navbar,
        .nav-bar,
        [class*="Navbar"],
        [class*="navbar"],
        [class*="Header"]:not(h1):not(h2):not(h3):not(h4),
        [id*="navbar"],
        [id*="header"],
        
        /* Sembunyikan footer website */
        footer,
        .footer,
        [class*="Footer"],
        [class*="footer"],
        [id*="footer"],
        
        /* Sembunyikan bottom navigation */
        .bottom-nav,
        .bottom-menu,
        [class*="BottomNav"],
        [class*="bottom-nav"],
        [class*="BottomMenu"],
        [id*="bottom-nav"],
        
        /* Fixed/sticky elemen navigasi */
        .sticky-top,
        .fixed-top,
        .fixed-bottom
        { 
          display: none !important; 
          visibility: hidden !important;
        }
        
        /* Hilangkan padding-top yang biasanya dibuat untuk navbar */
        body { 
          padding-top: 0 !important;
          margin-top: 0 !important;
        }
      `;
      document.head.appendChild(style);
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
