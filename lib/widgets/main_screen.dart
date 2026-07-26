import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/products_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/studio/studio_screen.dart';

// Global key untuk akses MainScreen dari widget lain
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  MainScreen() : super(key: mainScreenKey);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ProductsScreenState> _productsScreenKey =
      GlobalKey<ProductsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ProductsScreen(key: _productsScreenKey, autoFocusSearch: false),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
  }

  // Method untuk switch ke tab products dengan filter kategori
  void goToProductsWithCategory(String categorySlug) {
    setState(() {
      _currentIndex = 1; // Index tab "Cari"
    });
    // Gunakan addPostFrameCallback untuk memastikan widget sudah fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tambahkan delay kecil untuk memastikan state update
      Future.delayed(const Duration(milliseconds: 100), () {
        print('[MainScreen] Applying category filter: $categorySlug');
        _productsScreenKey.currentState?.applyCategory(categorySlug);
      });
    });
  }

  // Method untuk switch ke tab products tanpa filter
  void goToProducts() {
    setState(() {
      _currentIndex = 1;
    });
  }

  // Method untuk switch ke tab products dengan focus search
  void goToProductsWithSearch() {
    setState(() {
      _currentIndex = 1;
    });
    // Focus search field setelah tab switch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        print('[MainScreen] Focusing search field');
        _productsScreenKey.currentState?.focusSearch();
      });
    });
  }

  // Method untuk switch ke tab orders
  void goToOrders() {
    setState(() {
      _currentIndex = 3; // Index tab "Pesanan"
    });
  }

  // Method untuk navigate ke Studio Pesanan (for sellers)
  void goToStudioOrders() {
    // Navigate to Studio screen with Pesanan tab
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const StudioScreen(initialTab: 2), // Tab index 2 = Pesanan
      ),
    );
  }

  // Method untuk switch ke tab profile
  void goToProfile() {
    setState(() {
      _currentIndex = 4; // Index tab "Akun"
    });
  }

  // Build icon dengan floating effect untuk active state
  Widget _buildNavIcon(IconData icon, int index) {
    return Icon(icon, size: 24);
  }

  Widget _buildActiveNavIcon(IconData icon, int index) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color(
          0xFFFBBF24,
        ).withOpacity(0.15), // amber-400 exact from website
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(
            0xFF1C1A14,
          ), // Exact website bottom menu color (same as navbar)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Color(
                0xFF78350F,
              ).withOpacity(0.4), // amber-900/40 exact from website
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFFFBBF24), // amber-400 exact from website
          unselectedItemColor: Color(
            0xFFB45309,
          ), // amber-700 exact from website
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, 0),
              activeIcon: _buildActiveNavIcon(Icons.home, 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.search_outlined, 1),
              activeIcon: _buildActiveNavIcon(Icons.search, 1),
              label: 'Cari',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.shopping_cart_outlined, 2),
              activeIcon: _buildActiveNavIcon(Icons.shopping_cart, 2),
              label: 'Keranjang',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.receipt_long_outlined, 3),
              activeIcon: _buildActiveNavIcon(Icons.receipt_long, 3),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outlined, 4),
              activeIcon: _buildActiveNavIcon(Icons.person, 4),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
