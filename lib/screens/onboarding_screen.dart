import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _contentAnim;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  static const _pages = [
    _OnboardingData(
      image: 'assets/card1.png',
      title: 'Karya Autentik\nLangsung dari Seniman',
      description:
          'Jelajahi ribuan karya kerajinan batu, batik tulis, ukiran, hingga perhiasan dari seniman dan pengrajin lokal terbaik Indonesia.',
    ),
    _OnboardingData(
      image: 'assets/card2.png',
      title: 'Ruang Budaya\n& Komunitas',
      description:
          'Temukan kisah di balik setiap karya, artikel budaya, serta event komunitas seni Nusantara dalam satu genggaman.',
    ),
    _OnboardingData(
      image: 'assets/card3.png',
      title: 'Keamanan Transaksi\n& Pengiriman',
      description:
          'Sistem pembayaran terproteksi dengan jaminan barang sesuai deskripsi dan pengemasan standar karya seni tinggi.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentFade = CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut));
    _contentAnim.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnim.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _contentAnim.reset();
    _contentAnim.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0A),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/background-splash-dan-card.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),

          // Main layout
          SafeArea(
            child: Column(
              children: [
                // ─── Header: Logo + Skip ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini logo text
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'serif',
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(
                              text: 'MAJA\n',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            TextSpan(
                              text: 'CRAFT',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 11,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Skip button
                      GestureDetector(
                        onTap: _finish,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Page View ────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        data: _pages[index],
                        contentFade: index == _currentPage
                            ? _contentFade
                            : AlwaysStoppedAnimation(0.0),
                        contentSlide: index == _currentPage
                            ? _contentSlide
                            : const AlwaysStoppedAnimation(Offset(0, 0.12)),
                        imageHeight: size.height * 0.35,
                      );
                    },
                  ),
                ),

                // ─── Footer: Dots + Button ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page dots
                      Row(
                        children: List.generate(3, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Next / Finish button
                      GestureDetector(
                        onTap: _next,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: isLast ? 24 : 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFB8962C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast ? 'Jelajahi MajaCraft' : 'Lanjut',
                                style: const TextStyle(
                                  color: Color(0xFF1C1A14),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF1C1A14),
                                size: 18,
                              ),
                            ],
                          ),
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
    );
  }
}

// ─── Data model ────────────────────────────────────────────────────────────────

class _OnboardingData {
  final String image;
  final String title;
  final String description;

  const _OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}

// ─── Single onboarding page ────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final double imageHeight;

  const _OnboardingPage({
    required this.data,
    required this.contentFade,
    required this.contentSlide,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // ─── Image card ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: imageHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    data.image,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight * 0.3,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC0D0C0A)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ─── Text content with animation ─────────────────────────────────
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative gold line
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFB8962C)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  Text(
                    data.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
