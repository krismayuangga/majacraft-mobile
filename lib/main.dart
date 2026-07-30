import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'providers/wishlist_provider.dart';
import 'utils/nav_key.dart';
import 'screens/splash_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/store_detail_screen.dart';
import 'services/api_service.dart';
import 'models/product.dart';
import 'services/fcm_service.dart';
import 'services/deep_link_service.dart';
import 'widgets/main_screen.dart';

// Re-export navigatorKey agar kode lain yang sudah import main.dart tetap bisa
export 'utils/nav_key.dart' show navigatorKey;

/// Background FCM handler — HARUS top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tidak perlu inisialisasi Firebase di sini karena sudah diinit di main()
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase.initializeApp() cepat (~100-300ms) — aman di main()
  await Firebase.initializeApp();

  // onBackgroundMessage WAJIB dipanggil sebelum runApp() per Firebase docs
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inisialisasi deep link handler
  DeepLinkService().initialize();

  // runApp() langsung — FCMService.initialize() (permission request yang lambat)
  // dipindah ke SplashScreen agar berjalan paralel dengan animasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: 'MajaCraft',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey, // Global key untuk navigasi notifikasi
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/product-by-slug') {
            final slug = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => _ProductBySlugLoader(slug: slug),
            );
          }
          if (settings.name == '/store') {
            final slug = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => StoreDetailScreen(storeSlug: slug),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state and load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();
    final wishlistProvider = context.read<WishlistProvider>();

    // Initialize auth (check if user is logged in)
    await authProvider.initialize();

    // Setup FCM handlers untuk navigasi notifikasi
    FCMService().setupForegroundHandlers(context);

    // If user is authenticated, load wishlist
    if (authProvider.isAuthenticated && authProvider.token != null) {
      try {
        await wishlistProvider.loadWishlists(authProvider.token!);
      } catch (e) {
        print('[AppInitializer] Error loading wishlist: $e');
        // Don't block app if wishlist fails to load
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat aplikasi...'),
                ],
              ),
            ),
          );
        }

        // Show error if initialization failed
        if (authProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${authProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().initialize();
                    },
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show main screen
        return MainScreen();
      },
    );
  }
}

/// Load produk by slug untuk deep link, lalu buka ProductDetailScreen
class _ProductBySlugLoader extends StatefulWidget {
  final String slug;
  const _ProductBySlugLoader({required this.slug});

  @override
  State<_ProductBySlugLoader> createState() => _ProductBySlugLoaderState();
}

class _ProductBySlugLoaderState extends State<_ProductBySlugLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiService();
      final resp = await api.get('/api/products?search=${widget.slug}&limit=1');
      final items = resp['data']?['items'] as List? ?? [];
      if (items.isNotEmpty && mounted) {
        final product = Product.fromJson(items.first);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
