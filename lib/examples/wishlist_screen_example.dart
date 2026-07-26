import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wishlist.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';

/// Wishlist Screen - Display all wishlisted products
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    if (authProvider.isAuthenticated && authProvider.token != null) {
      try {
        await wishlistProvider.loadWishlists(authProvider.token!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat wishlist: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    if (authProvider.token == null) return;

    try {
      await wishlistProvider.removeFromWishlist(productId, authProvider.token!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari wishlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          // Loading state
          if (wishlistProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            );
          }

          // Empty state
          if (wishlistProvider.wishlists.isEmpty) {
            return _buildEmptyState();
          }

          // Wishlist items
          return RefreshIndicator(
            onRefresh: _loadWishlists,
            color: const Color(0xFFD4AF37),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: wishlistProvider.wishlists.length,
              itemBuilder: (context, index) {
                final wishlist = wishlistProvider.wishlists[index];
                final product = wishlist.product;

                if (product == null) {
                  return const SizedBox(); // Skip if product not loaded
                }

                return _buildProductCard(wishlist, product);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Wishlist Kosong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk favoritmu di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home/products
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Jelajahi Produk'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Wishlist wishlist, dynamic product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to product detail
          // Navigator.pushNamed(context, '/product-detail', arguments: product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with remove button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    product.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 40),
                      );
                    },
                  ),
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      _showRemoveDialog(wishlist.productId, product.name);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                // PHYGITAL badge
                if (product.hasNFT)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade700,
                            Colors.blue.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PHYGITAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      'Rp ${_formatPrice(product.price)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                      ),
                    ),

                    const Spacer(),

                    // Rating & Sold
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.sold} terjual',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari Wishlist?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$productName" dari wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromWishlist(productId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
