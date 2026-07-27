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

    // Load Featured Products
    try {
      final response = await ApiService().get(
        '/api/products?featured=1&limit=6',
        token: token,
      );

      if (response['data'] != null && response['data']['items'] != null) {
        final items = response['data']['items'] as List;
        setState(() {
          _featuredProducts = items
              .map((item) => Product.fromJson(item))
              .toList();
          _isLoadingFeatured = false;
        });
      } else {
        setState(() {
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      print('[Home] Error loading featured products: $e');
      setState(() {
        _isLoadingFeatured = false;
      });
    }

    // Load New Products
    try {
      final response = await ApiService().get(
        '/api/products?sort=terbaru&limit=6',
        token: token,
      );

      if (response['data'] != null && response['data']['items'] != null) {
        final items = response['data']['items'] as List;
        setState(() {
          _newProducts = items.map((item) => Product.fromJson(item)).toList();
          _isLoadingNew = false;
        });
      } else {
        setState(() {
          _isLoadingNew = false;
        });
      }
    } catch (e) {
      print('[Home] Error loading new products: $e');
      setState(() {
        _isLoadingNew = false;
      });
    }

    // Load Certified Products
    try {
      final response = await ApiService().get(
        '/api/products?sertifikat=1&limit=10',
        token: token,
      );

      if (response['data'] != null && response['data']['items'] != null) {
        final items = response['data']['items'] as List;
        setState(() {
          _certifiedProducts = items
              .map((item) => Product.fromJson(item))
              .take(6)
              .toList();
          _isLoadingCertified = false;
        });
      } else {
        setState(() {
          _isLoadingCertified = false;
        });
      }
    } catch (e) {
      print('[Home] Error loading certified products: $e');
      setState(() {
        _isLoadingCertified = false;
      });
    }

    // Load Flash Sale Products (products with discounts)
    try {
      // Try to get flash sale products from API
      var response = await ApiService().get(
        '/api/products?flashSale=1&limit=20',
        token: token,
      );

      // If no flash sale endpoint, fallback to filtering by discount
      if (response['data'] == null ||
          response['data']['items'] == null ||
          (response['data']['items'] as List).isEmpty) {
        response = await ApiService().get(
          '/api/products?limit=50',
          token: token,
        );
      }

      if (response['data'] != null && response['data']['items'] != null) {
        final items = response['data']['items'] as List;
        // Filter products with discounts
        final flashSaleItems = items
            .map((item) => Product.fromJson(item))
            .where(
              (product) =>
                  product.originalPrice != null &&
                  product.originalPrice! > product.price,
            )
            .toList();

        print('[Home] Found ${flashSaleItems.length} flash sale products');

        setState(() {
          _flashSaleProducts = flashSaleItems;
          _isLoadingFlashSale = false;
        });
      } else {
        setState(() {
          _isLoadingFlashSale = false;
        });
      }
    } catch (e) {
      print('[Home] Error loading flash sale products: $e');
      setState(() {
        _isLoadingFlashSale = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
