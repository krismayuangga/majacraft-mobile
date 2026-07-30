import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../utils/nav_key.dart';

/// Handles App Links (https://majacraft.id/...) → navigasi ke screen yang tepat
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();

  /// Inisialisasi listener — panggil sekali di main.dart setelah Firebase.initializeApp()
  Future<void> initialize() async {
    // Handle link saat app TERMINATED (cold start)
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      // Delay agar navigator sudah siap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleLink(initialLink);
        });
      });
    }

    // Handle link saat app BACKGROUND (warm start)
    _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final path = uri.path; // e.g. /produk/batik-tulis-solo

    if (path.startsWith('/produk/')) {
      final slug = path.replaceFirst('/produk/', '');
      if (slug.isNotEmpty) _openProduct(nav, slug);
    } else if (path.startsWith('/verifikasi/')) {
      final id = path.replaceFirst('/verifikasi/', '');
      if (id.isNotEmpty) _openVerification(nav, id);
    } else if (path.startsWith('/toko/')) {
      final slug = path.replaceFirst('/toko/', '');
      if (slug.isNotEmpty) _openStore(nav, slug);
    }
  }

  void _openProduct(NavigatorState nav, String slug) {
    nav.pushNamed('/product-by-slug', arguments: slug);
  }

  void _openVerification(NavigatorState nav, String id) {
    nav.pushNamed('/verification', arguments: id);
  }

  void _openStore(NavigatorState nav, String slug) {
    nav.pushNamed('/store', arguments: slug);
  }
}
