import 'package:flutter/material.dart';
import '../models/product.dart';
import 'flash_sale_product_card.dart';

class FlashSaleBanner extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onViewAll;

  const FlashSaleBanner({
    super.key,
    required this.products,
    required this.onViewAll,
  });

  @override
  State<FlashSaleBanner> createState() => _FlashSaleBannerState();
}

class _FlashSaleBannerState extends State<FlashSaleBanner>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shineController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shineAnimation;

  @override
  void initState() {
    super.initState();

    print('[FlashSaleBanner] Received ${widget.products.length} products');

    // Pulse animation for flash icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shine animation for background
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shineAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF5C3D2E),
            const Color(0xFF4A2F21),
            const Color(0xFF3D2317),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shine animation overlay
          Stack(
            children: [
              AnimatedBuilder(
                animation: _shineAnimation,
                builder: (context, child) {
                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_shineAnimation.value, -1),
                        end: Alignment(_shineAnimation.value + 0.5, 0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    // Flash icon with pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Color(0xFFB45309),
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),

                    // Title
                    const Text(
                      'FLASH SALE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const Spacer(),

                    // View All button
                    GestureDetector(
                      onTap: widget.onViewAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Products
          if (widget.products.isNotEmpty)
            SizedBox(
              height: 253,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                itemCount: widget.products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 140,
                    child: FlashSaleProductCard(
                      product: widget.products[index],
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Belum ada produk flash sale',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
