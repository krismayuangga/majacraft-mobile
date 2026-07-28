import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'onboarding_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/main_screen.dart';
import '../services/fcm_service.dart';
import '../utils/nav_key.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Hide status bar for full immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200), // lebih lambat
    );

    // Logo: fade-in + scale-up lebih halus
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.55,
          curve: Curves.easeOut,
        ), // easeOut bukan easeOutBack agar tidak bounce
      ),
    );

    // Tagline fades in slightly later
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );

    // Jalankan animasi + Firebase init BERSAMAAN (parallel)
    // sehingga splash sudah tampil sambil Firebase loading di background
    _controller.forward();
    _initFirebaseAndNavigate();
  }

  Future<void> _initFirebaseAndNavigate() async {
    // Animasi + FCM init jalan bersamaan
    // Total minimum: 3.5 detik (animasi 2.2s + hold 1.3s)
    await Future.wait([
      _initFCMPermission(),
      Future.delayed(const Duration(milliseconds: 3500)),
    ]);
    _navigate();
  }

  Future<void> _initFCMPermission() async {
    try {
      // Firebase sudah diinit di main() — di sini hanya minta izin notifikasi
      await FCMService().initialize();
      FCMService.setNavigatorKey(navigatorKey);
    } catch (_) {
      // Jika gagal, tetap lanjut ke app
    }
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      return;
    }

    // User already saw onboarding → check auth
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Await refresh dari server — pastikan data terbaru (phone, image, dll) tersimpan
      await authProvider.refreshUserData();
      try {
        await context.read<WishlistProvider>().loadWishlists(
          authProvider.token!,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0908),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image — contain to show corner ornaments
          Container(
            color: const Color(0xFF0A0908),
            child: Center(
              child: Image.asset(
                'assets/background-splash-dan-card.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Dark overlay gradient for depth
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0x00000000), Color(0xCC000000)],
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with glow effect
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            // Glow halus — opacity rendah, spread kecil
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.18),
                              blurRadius: 45,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.08),
                              blurRadius: 90,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo-maja-splash.png',
                          width: 240,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Tagline
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _taglineFade,
                    child: Column(
                      children: [
                        // Decorative line
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 1,
                              color: const Color(0xFFD4AF37).withOpacity(0.6),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.diamond_outlined,
                              color: Color(0xFFD4AF37),
                              size: 12,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 1,
                              color: const Color(0xFFD4AF37).withOpacity(0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Menghubungkan Warisan Budaya\ndengan Inovasi Digital',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            color: const Color(0xFFD4AF37).withOpacity(0.85),
                            letterSpacing: 0.8,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loading dots
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        final progress = (_controller.value * 3 - i).clamp(
                          0.0,
                          1.0,
                        );
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.lerp(
                              const Color(0xFFD4AF37).withOpacity(0.3),
                              const Color(0xFFD4AF37),
                              progress,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
