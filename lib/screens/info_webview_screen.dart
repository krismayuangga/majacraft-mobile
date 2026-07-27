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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
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
