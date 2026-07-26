import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isTogglingWishlist = false;

  Future<void> _toggleWishlist() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isTogglingWishlist = true);

    try {
      final wishlistProvider = context.read<WishlistProvider>();
      await wishlistProvider.toggleWishlist(
        widget.product.id,
        authProvider.token!,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingWishlist = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isWishlisted = wishlistProvider.isProductWishlisted(
          widget.product.id,
        );

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailScreen(product: widget.product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          widget.product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // PHYGITAL Badge (Certified)
                    if (widget.product.hasNFT)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: const Color(0xFFB45309),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 9,
                                color: Color(0xFFB45309),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'PHYGITAL',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Wishlist Button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: _isTogglingWishlist ? null : _toggleWishlist,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isTogglingWishlist
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.red.shade400,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 14,
                                  color: isWishlisted
                                      ? Colors.red.shade400
                                      : Colors.grey.shade600,
                                ),
                        ),
                      ),
                    ),

                    // Discount Badge
                    if (widget.product.discountPercentage != null)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-${widget.product.discountPercentage}%',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name
                        Expanded(
                          flex: 2,
                          child: Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 3),

                        // Price
                        Row(
                          children: [
                            Text(
                              widget.product.formattedPrice,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            if (widget.product.formattedOriginalPrice !=
                                null) ...[
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  widget.product.formattedOriginalPrice!,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Seller Info
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 9,
                              color: Colors.brown.shade700,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                widget.product.sellerLocation,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Rating and Sold
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 10,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.product.sold} terjual',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
      },
    );
  }
}
