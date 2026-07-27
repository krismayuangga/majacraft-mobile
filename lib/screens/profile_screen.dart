import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/main_screen.dart';
import 'auth/login_screen.dart';
import 'kyc_screen.dart';
import 'wishlist_screen.dart';
import 'edit_profile_screen.dart';
import 'address_list_screen.dart';
import 'security_screen.dart';
import 'notification_list_screen.dart';
import 'notification_settings_screen.dart';
import 'info_webview_screen.dart';
import 'studio/studio_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _orderCount = 0;
  int _reviewCount = 0;
  int _wishlistCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    try {
      final apiService = ApiService();

      // Fetch profile with stats
      final response = await apiService.get(
        '/api/users/me',
        token: authProvider.token,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final count = data['_count'] as Map<String, dynamic>?;

        // Update KYC status if available from backend
        if (data['kycStatus'] != null) {
          final newKycStatus = data['kycStatus'] as String;
          if (authProvider.user?.kycStatus != newKycStatus) {
            print('[Profile] Updating KYC status from backend: $newKycStatus');
            await authProvider.updateKycStatus(newKycStatus);
          }
        }

        setState(() {
          _orderCount = count?['orders'] ?? 0;
          _reviewCount = count?['reviews'] ?? 0;
          _wishlistCount = count?['wishlists'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('[Profile] Error loading stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _navigateToKYC(BuildContext context) async {
    // Navigate to KYC screen and wait for result
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KYCScreen()),
    );

    // Refresh UI after returning from KYC screen
    if (mounted) {
      setState(() {
        // Trigger rebuild to show updated KYC status
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: const Color(0xFF4A2F21), // Same as bottom menu
            appBar: AppBar(
              title: const Text('Akun', style: TextStyle(color: Colors.white)),
              centerTitle: true,
              backgroundColor: const Color(0xFF4A2F21), // Same as bottom menu
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outlined,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login Required',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan login untuk mengakses profil',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF653611),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        }

        final user = authProvider.user!;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Functional Header - Like Web Version
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient Background with Curved Bottom
                    ClipPath(
                      clipper: _ProfileHeaderClipper(),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(
                                0xFF4A2F21,
                              ), // Same as bottom menu - medium brown
                              const Color(
                                0xFF5C3D2E,
                              ), // Same as bottom menu - lighter brown
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.03),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              left: -40,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.02),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Profile Row - Avatar + Info
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar - Left Side
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.white,
                                    backgroundImage:
                                        user.image != null &&
                                            user.image!.isNotEmpty
                                        ? NetworkImage(
                                            user.image!.startsWith('http')
                                                ? user.image!
                                                : 'https://majacraft.id${user.image!}',
                                          )
                                        : null,
                                    child:
                                        user.image == null ||
                                            user.image!.isEmpty
                                        ? Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(
                                                    0xFF653611,
                                                  ).withOpacity(0.1),
                                                  const Color(
                                                    0xFF653611,
                                                  ).withOpacity(0.05),
                                                ],
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              size: 35,
                                              color: Color(0xFF653611),
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Info - Center
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Email
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),

                                      // Badges Row
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          // Role Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  user.role == 'seller'
                                                      ? Icons.palette
                                                      : Icons.person,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.role == 'seller'
                                                      ? 'Seniman'
                                                      : 'Pembeli',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Verified Badge
                                          if (user.kycStatus == 'VERIFIED')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.withOpacity(
                                                      0.3,
                                                    ),
                                                    Colors.green.withOpacity(
                                                      0.2,
                                                    ),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.verified,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Terverifikasi',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Pending Badge
                                          if (user.kycStatus == 'PENDING')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.orange.withOpacity(
                                                      0.3,
                                                    ),
                                                    Colors.orange.withOpacity(
                                                      0.2,
                                                    ),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.orange
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.hourglass_bottom,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Verifikasi Diproses',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
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

                // Stats Row - Pesanan, Ulasan, Wishlist
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            _isLoadingStats ? '-' : _orderCount.toString(),
                            'Pesanan',
                            isDark: true,
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: Colors.grey[300],
                          ),
                          _buildStatItem(
                            _isLoadingStats ? '-' : _reviewCount.toString(),
                            'Ulasan',
                            isDark: true,
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: Colors.grey[300],
                          ),
                          _buildStatItem(
                            _isLoadingStats ? '-' : _wishlistCount.toString(),
                            'Wishlist',
                            isDark: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 0),

                // TRANSAKSI Section
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('TRANSAKSI'),
                      _buildMenuCard([
                        _MenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Pesanan Saya',
                          onTap: () {
                            // Navigate to orders tab using GlobalKey
                            mainScreenKey.currentState?.goToOrders();
                          },
                        ),
                        _MenuItem(
                          icon: Icons.favorite_outline,
                          title: 'Wishlist',
                          badge: _wishlistCount > 0
                              ? _wishlistCount.toString()
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WishlistScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ],
                  ),
                ),

                // PENGATURAN AKUN Section
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('PENGATURAN AKUN'),
                      _buildMenuCard([
                        _MenuItem(
                          icon: Icons.person_outline,
                          title: 'Data Diri',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            // Refresh profile if data was updated
                            if (result == true) {
                              _loadUserStats();
                            }
                          },
                        ),
                        _MenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Alamat Pengiriman',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressListScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline,
                          title: 'Keamanan & Password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SecurityScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Notifikasi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationListScreen(),
                              ),
                            );
                          },
                        ),
                        _MenuItem(
                          icon: Icons.tune_outlined,
                          title: 'Pengaturan Notifikasi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ],
                  ),
                ),

                // PENGATURAN TOKO Section
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('PENGATURAN TOKO'),
                      _buildMenuCard([
                        if (user.role == 'seller')
                          _MenuItem(
                            icon: Icons.store_outlined,
                            title: 'Buka Studio Seniman',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudioScreen(),
                                ),
                              );
                            },
                          ),
                        if (user.role != 'seller')
                          _MenuItem(
                            icon: Icons.palette_outlined,
                            title: 'Jadi Seniman',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur upgrade ke seniman akan segera hadir',
                                  ),
                                ),
                              );
                            },
                          ),
                        _MenuItem(
                          icon: user.kycStatus == 'VERIFIED'
                              ? Icons.verified_user
                              : user.kycStatus == 'PENDING'
                              ? Icons.hourglass_bottom
                              : Icons.verified_user_outlined,
                          title: user.kycStatus == 'VERIFIED'
                              ? 'Verifikasi Akun (Terverifikasi)'
                              : user.kycStatus == 'PENDING'
                              ? 'Verifikasi Akun (Diproses)'
                              : 'Verifikasi Akun (KYC)',
                          badge: user.kycStatus == 'PENDING' ? '⏳' : null,
                          onTap: () {
                            if (user.kycStatus != 'VERIFIED') {
                              _navigateToKYC(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Akun Anda sudah terverifikasi',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                        _MenuItem(
                          icon: Icons.help_outline,
                          title: 'Bantuan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InfoWebViewScreen(
                                  title: 'Pusat Bantuan',
                                  url: 'https://majacraft.id/bantuan',
                                ),
                              ),
                            );
                          },
                        ),
                        _MenuItem(
                          icon: Icons.info_outline,
                          title: 'Tentang MajaCraft',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _TentangScreen(),
                              ),
                            );
                          },
                        ),
                      ]),
                    ],
                  ),
                ),

                // Logout Button
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Keluar dari Akun'),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            await authProvider.logout();
                          }
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Version Footer
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, top: 8),
                      child: Text(
                        'MajaCraft v1.0',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
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

  Widget _buildStatItem(String count, String label, {bool isDark = false}) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF653611) : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[600] : Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Icon(
                  item.icon,
                  color: const Color(0xFF653611),
                  size: 22,
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
                onTap: item.onTap,
              ),
              if (!isLast)
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.badge,
    required this.onTap,
  });
}

// Custom clipper for rectangular shape with rounded bottom corners
class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 20.0;

    // Start from top-left corner
    path.moveTo(0, 0);

    // Top-right corner
    path.lineTo(size.width, 0);

    // Go down the right side
    path.lineTo(size.width, size.height - radius);

    // Bottom-right rounded corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // Bottom edge
    path.lineTo(radius, size.height);

    // Bottom-left rounded corner
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Close path back to start
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ─── Tentang MajaCraft Screen ─────────────────────────────────────────────────

class _TentangScreen extends StatelessWidget {
  const _TentangScreen();

  static const _baseUrl = 'https://majacraft.id';

  static const _layanan = [
    {'title': 'Cara Berbelanja', 'url': '$_baseUrl/cara-berbelanja'},
    {'title': 'Cara Berjualan', 'url': '$_baseUrl/cara-berjualan'},
    {'title': 'Sertifikat Phygital', 'url': '$_baseUrl/phygital'},
    {'title': 'Ruang Budaya', 'url': '$_baseUrl/ruang-budaya'},
    {'title': 'Program Seniman', 'url': '$_baseUrl/program-seniman'},
    {'title': 'Pusat Bantuan', 'url': '$_baseUrl/bantuan'},
  ];

  static const _informasi = [
    {'title': 'Tentang MajaCraft', 'url': '$_baseUrl/tentang'},
    {'title': 'Kebijakan Privasi', 'url': '$_baseUrl/kebijakan-privasi'},
    {'title': 'Syarat & Ketentuan', 'url': '$_baseUrl/syarat-ketentuan'},
    {'title': 'Keamanan Transaksi', 'url': '$_baseUrl/keamanan-transaksi'},
    {'title': 'Karir', 'url': '$_baseUrl/karir'},
    {'title': 'Hubungi Kami', 'url': '$_baseUrl/hubungi-kami'},
  ];

  void _openPage(BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfoWebViewScreen(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: const Text(
          'Tentang MajaCraft',
          style: TextStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Branding header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1A14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  'MajaCraft',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Marketplace Kerajinan & Seni Indonesia',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Layanan
          _buildSection(
            context,
            title: 'LAYANAN',
            icon: Icons.miscellaneous_services_outlined,
            items: _layanan,
          ),
          const SizedBox(height: 12),

          // Informasi
          _buildSection(
            context,
            title: 'INFORMASI',
            icon: Icons.info_outline,
            items: _informasi,
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text(
              '© 2026 MajaCraft. All rights reserved.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF653611)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF653611),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, indent: 16),
                  ListTile(
                    title: Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A), // hitam tegas, mudah dibaca
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Color(0xFF653611), // ikon coklat brand
                    ),
                    onTap: () =>
                        _openPage(context, item['title']!, item['url']!),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
