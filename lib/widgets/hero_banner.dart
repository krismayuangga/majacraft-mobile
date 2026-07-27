import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/ruang_budaya_screen.dart';
import 'main_screen.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<BannerData> _banners = [
    BannerData(
      title: 'Ruang Budaya',
      subtitle:
          'Telusuri artikel budaya, cerita karya seniman, dan acara komunitas seni Indonesia',
      primaryCta: 'Lihat Acara',
      secondaryCta: 'Jual Karya',
      accent: 'Komunitas & Event',
      image: 'https://majacraft.id/images/banner-ruang-budaya.jpg',
    ),
    BannerData(
      title: 'Batik Warisan Dunia',
      subtitle: 'Koleksi batik tulis tangan langsung dari pengrajin asli',
      primaryCta: 'Lihat Koleksi Batik',
      secondaryCta: 'Jual Karya',
      accent: 'UNESCO Heritage',
      image: 'https://majacraft.id/images/banner-2.jpg',
    ),
    BannerData(
      title: 'Kerajinan Batu Candi',
      subtitle: 'Ukiran batu andesit bergaya Majapahit oleh maestro Jawa',
      primaryCta: 'Lihat Koleksi',
      secondaryCta: 'Jual Karya',
      accent: 'Sertifikat Digital',
      image: 'https://majacraft.id/images/banner-3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(color: Color(0xFF1C1A14)),
      child: Stack(
        children: [
          // Banner PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _startAutoPlay();
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _BannerItem(banner: _banners[index]);
            },
          ),

          // Indicator dots - golden theme
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFFFBBF24) // Active golden (amber-400)
                        : const Color(
                            0xFF78350F,
                          ).withOpacity(0.4), // Inactive (amber-900/40)
                    borderRadius: BorderRadius.circular(4),
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

class _BannerItem extends StatelessWidget {
  final BannerData banner;

  const _BannerItem({required this.banner});

  void _handlePrimaryAction(BuildContext context) {
    // Navigate based on banner title
    if (banner.title == 'Ruang Budaya') {
      // Lihat Acara → Ruang Budaya screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RuangBudayaScreen()),
      );
    } else if (banner.title == 'Batik Warisan Dunia') {
      // Lihat Koleksi Batik → batik-kain category
      mainScreenKey.currentState?.goToProductsWithCategory('batik-kain');
    } else if (banner.title == 'Kerajinan Batu Candi') {
      // Lihat Koleksi → kerajinan-batu category
      mainScreenKey.currentState?.goToProductsWithCategory('kerajinan-batu');
    }
  }

  void _handleSecondaryAction(BuildContext context) {
    // Jual Karya → Navigate to Profile tab (Akun) where Studio Seniman option is
    mainScreenKey.currentState?.goToProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with caching
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: banner.image,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: const Color(0xFF1C1A14)),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.brown.shade900, Colors.brown.shade800],
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        Positioned(
          left: 16,
          right: 16,
          top: 35,
          bottom: 35,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Accent badge - exact website style
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(
                    0xFF7A3206,
                  ).withOpacity(0.5), // Exact from website
                  border: Border.all(
                    color: Color(
                      0xFFE17200,
                    ).withOpacity(0.5), // Exact from website
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: Color(0xFFFFD230), // Exact from website
                    ),
                    const SizedBox(width: 6),
                    Text(
                      banner.accent,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFD230), // Exact from website
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Title - exact website style (white)
              Text(
                banner.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700, // 700 from website
                  color: Colors.white, // Pure white from website
                  height: 1.2,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 8,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle - exact website style (light yellow with opacity)
              Text(
                banner.subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(
                    0xFFFEE686,
                  ).withOpacity(0.8), // Exact from website
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              // Buttons row - primary and secondary like website
              Row(
                children: [
                  // Primary Button - exact website gradient
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFA07830), // Bronze start
                          Color(0xFFC9A84C), // Gold middle
                          Color(0xFFA07830), // Bronze end
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF7A3207).withOpacity(0.4),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Color(0xFF7A3207).withOpacity(0.4),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handlePrimaryAction(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Color(0xFF1C1A14), // Dark text
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        banner.primaryCta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Secondary Button - exact website style (transparent with border)
                  Container(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _handleSecondaryAction(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFFFEE685), // Light yellow text
                        side: BorderSide(
                          color: Color(
                            0xFFFD9900,
                          ).withOpacity(0.6), // Orange border
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        banner.secondaryCta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BannerData {
  final String title;
  final String subtitle;
  final String primaryCta;
  final String secondaryCta;
  final String accent;
  final String image;

  BannerData({
    required this.title,
    required this.subtitle,
    required this.primaryCta,
    required this.secondaryCta,
    required this.accent,
    required this.image,
  });
}
