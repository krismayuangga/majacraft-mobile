import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/hero_banner.dart';
import '../widgets/category_grid.dart';
import '../widgets/flash_sale_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/main_screen.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  final void Function({
    bool? initialFeatured,
    bool? initialCertified,
    bool? initialFlashSale,
    String? initialSort,
  })?
  onNavigateToProducts;
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onNavigateToProducts, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingFeatured = true;
  bool _isLoadingNew = true;
  bool _isLoadingCertified = true;
  bool _isLoadingFlashSale = true;
  List<Product> _featuredProducts = [];
  List<Product> _newProducts = [];
  List<Product> _certifiedProducts = [];
  List<Product> _flashSaleProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    final api = ApiService();

    // ── Semua 4 request jalan BERSAMAAN (parallel), bukan berurutan ──
    final results = await Future.wait([
      api
          .get('/api/products?featured=1&limit=6', token: token)
          .catchError((_) => <String, dynamic>{}),
      api
          .get('/api/products?sort=terbaru&limit=6', token: token)
          .catchError((_) => <String, dynamic>{}),
      api
          .get('/api/products?sertifikat=1&limit=6', token: token)
          .catchError((_) => <String, dynamic>{}),
      api
          .get('/api/products?flashSale=1&limit=20', token: token)
          .catchError((_) => <String, dynamic>{}),
    ]);

    if (!mounted) return;

    List<Product> _parse(Map<String, dynamic> response) {
      try {
        if (response['data']?['items'] == null) return [];
        return (response['data']['items'] as List)
            .map((item) => Product.fromJson(item))
            .toList();
      } catch (_) {
        return [];
      }
    }

    final featured = _parse(results[0]);
    final newest = _parse(results[1]);
    final certified = _parse(results[2]);
    final flashSaleRaw = _parse(results[3]);
    // Filter flash sale: produk yang punya harga asli > harga jual
    final flashSale = flashSaleRaw
        .where((p) => p.originalPrice != null && p.originalPrice! > p.price)
        .toList();

    setState(() {
      _featuredProducts = featured;
      _newProducts = newest;
      _certifiedProducts = certified;
      _flashSaleProducts = flashSale;
      _isLoadingFeatured = false;
      _isLoadingNew = false;
      _isLoadingCertified = false;
      _isLoadingFlashSale = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        shouldPoll: true, // Hanya HomeScreen yang polling badge
        onSearchTap:
            widget.onSearchTap ??
            () {
              // Fallback to mainScreenKey if callback not provided
              mainScreenKey.currentState?.goToProductsWithSearch();
            },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isLoadingFeatured = true;
            _isLoadingNew = true;
            _isLoadingCertified = true;
            _isLoadingFlashSale = true;
          });
          await _loadProducts();
        },
        child: ListView(
          children: [
            // Hero Banner
            const HeroBanner(),

            // Category Grid
            CategoryGrid(
              onViewAll: () {
                widget.onNavigateToProducts?.call();
              },
            ),

            const SizedBox(height: 12),

            // Flash Sale Banner
            if (!_isLoadingFlashSale && _flashSaleProducts.isNotEmpty)
              FlashSaleBanner(
                products: _flashSaleProducts,
                onViewAll: () {
                  widget.onNavigateToProducts?.call(initialFlashSale: true);
                },
              ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // Featured Products Section
            _ProductSection(
              title: 'Karya Pilihan',
              subtitle: 'Mahakarya terpilih dari seniman terbaik Nusantara',
              products: _featuredProducts,
              isLoading: _isLoadingFeatured,
              onViewAll: () {
                widget.onNavigateToProducts?.call(initialFeatured: true);
              },
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),

            // New Products Section
            _ProductSection(
              title: 'Baru Ditambahkan',
              subtitle: 'Karya seni terbaru yang baru saja didaftarkan',
              products: _newProducts,
              isLoading: _isLoadingNew,
              onViewAll: () {
                widget.onNavigateToProducts?.call(initialSort: 'terbaru');
              },
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),

            // Certified Collection Section
            _ProductSection(
              title: 'Koleksi Bersertifikat',
              subtitle: 'Setiap karya dilengkapi dokumen kepemilikan resmi',
              products: _certifiedProducts,
              isLoading: _isLoadingCertified,
              onViewAll: () {
                widget.onNavigateToProducts?.call(initialCertified: true);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Product> products;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const _ProductSection({
    required this.title,
    required this.subtitle,
    required this.products,
    required this.isLoading,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 56,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(
                    'Lihat Semua →',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          if (isLoading)
            SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFB45309),
                ),
              ),
            )
          else if (products.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada produk',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 160,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < products.length - 1 ? 12 : 0,
                      ),
                      child: ProductCard(product: products[index]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
