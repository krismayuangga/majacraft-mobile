import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';

/// Example: Product Detail Screen with Wishlist Integration
class ProductDetailScreenExample extends StatefulWidget {
  final Product product;

  const ProductDetailScreenExample({super.key, required this.product});

  @override
  State<ProductDetailScreenExample> createState() =>
      _ProductDetailScreenExampleState();
}

class _ProductDetailScreenExampleState
    extends State<ProductDetailScreenExample> {
  bool _isTogglingWishlist = false;

  @override
  void initState() {
    super.initState();
    // Load wishlist status when screen opens
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    if (authProvider.isAuthenticated && authProvider.token != null) {
      // Load wishlists if not loaded yet
      if (wishlistProvider.wishlists.isEmpty) {
        try {
          await wishlistProvider.loadWishlists(authProvider.token!);
        } catch (e) {
          // Handle error silently for initial load
          print('Error loading wishlists: $e');
        }
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(
      context,
      listen: false,
    );

    // Check if user is logged in
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      _showLoginDialog();
      return;
    }

    setState(() => _isTogglingWishlist = true);

    try {
      final isNowWishlisted = await wishlistProvider.toggleWishlist(
        widget.product.id,
        authProvider.token!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowWishlisted
                  ? '✓ Ditambahkan ke wishlist'
                  : 'Dihapus dari wishlist',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isNowWishlisted ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingWishlist = false);
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text('Silakan login untuk menambahkan ke wishlist'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isWishlisted = wishlistProvider.isProductWishlisted(
          widget.product.id,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Produk'),
            actions: [
              // Wishlist Button with optimistic UI
              IconButton(
                icon: _isTogglingWishlist
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.grey,
                      ),
                onPressed: _isTogglingWishlist ? null : _toggleWishlist,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Image.network(
                  widget.product.image,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        'Rp ${_formatPrice(widget.product.price)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Wishlist Info (Optional)
                      if (isWishlisted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, size: 16, color: Colors.red),
                              SizedBox(width: 6),
                              Text(
                                'Di Wishlist',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
