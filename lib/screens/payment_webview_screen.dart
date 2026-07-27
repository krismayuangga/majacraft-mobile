import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';
import '../screens/order_detail_screen.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final String orderNumber;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    required this.orderNumber,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  final _orderService = OrderService(ApiService());

  bool _isLoading = true;
  bool _isPolling = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkRedirectUrl(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkRedirectUrl(url);
          },
          onProgress: (progress) {
            setState(() => _loadingProgress = progress);
          },
          onNavigationRequest: (request) {
            print('[PaymentWebView] Navigation: ${request.url}');
            _checkRedirectUrl(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            print('[PaymentWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// Intercept redirect URL untuk deteksi pembayaran selesai/dibatalkan
  void _checkRedirectUrl(String url) {
    // iPaymu success redirect: https://majacraft.id/pesanan?ref=ORDER_ID
    if (url.contains('majacraft.id/pesanan') && url.contains('ref=')) {
      _onPaymentSuccess();
      return;
    }

    // iPaymu cancel redirect: https://majacraft.id/checkout?cancel=ORDER_ID
    if (url.contains('majacraft.id/checkout') && url.contains('cancel=')) {
      _onPaymentCancelled();
      return;
    }
  }

  Future<void> _onPaymentSuccess() async {
    if (_isPolling) return;
    _isPolling = true;

    _showSnackBar('Pembayaran terdeteksi, memverifikasi...', Colors.blue);

    // Poll payment status max 60 detik
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      try {
        final status = await _orderService.checkPaymentStatus(
          widget.orderId,
          token: token,
        );

        print('[PaymentWebView] Payment status: $status');

        if (status != 'PENDING_PAYMENT') {
          _navigateToOrderDetail();
          return;
        }
      } catch (e) {
        print('[PaymentWebView] Error checking status: $e');
      }
    }

    // After polling, go to order detail regardless
    _navigateToOrderDetail();
  }

  void _onPaymentCancelled() {
    _showSnackBar('Pembayaran dibatalkan', Colors.orange);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _navigateToOrderDetail() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: widget.orderId),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<bool> _onWillPop() async {
    // Confirm back navigation
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Pembayaran?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar? Pesanan tetap tersimpan dan bisa dibayar di halaman Pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut Bayar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1A14),
          foregroundColor: const Color(0xFFFBBF24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pembayaran',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                widget.orderNumber,
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.pop(context);
            },
          ),
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
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
