import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/store.dart';
import '../../../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../add_product_screen.dart';

class StudioRingkasanTab extends StatefulWidget {
  final VoidCallback? onGoToPesanan;
  const StudioRingkasanTab({Key? key, this.onGoToPesanan}) : super(key: key);

  @override
  State<StudioRingkasanTab> createState() => _StudioRingkasanTabState();
}

class _StudioRingkasanTabState extends State<StudioRingkasanTab> {
  bool _isLoading = true;
  Store? _store;
  StudioStats? _stats;
  String? _error;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final token = authProvider.token;

      // Load store info
      final storeResponse = await apiService.get(
        '/api/studio/store',
        token: token,
      );
      if (storeResponse['success']) {
        _store = Store.fromJson(storeResponse['data']);
      }

      // Load stats (derived from products and orders)
      final productsResponse = await apiService.get(
        '/api/studio/products',
        token: token,
      );
      final ordersResponse = await apiService.get(
        '/api/studio/orders',
        token: token,
      );

      if (productsResponse['success'] && ordersResponse['success']) {
        final products = productsResponse['data'] as List;
        final orders = ordersResponse['data'] as List;

        // Calculate stats
        final activeProducts = products
            .where((p) => p['status'] == 'ACTIVE')
            .length;
        final activeOrders = orders
            .where(
              (o) => o['status'] == 'PROCESSING' || o['status'] == 'SHIPPED',
            )
            .length;
        final completedOrders = orders
            .where((o) => o['status'] == 'COMPLETED')
            .toList();
        final totalRevenue = completedOrders.fold<double>(
          0,
          (sum, order) => sum + (order['total'] as num).toDouble(),
        );

        _stats = StudioStats(
          totalRevenue: totalRevenue,
          activeOrders: activeOrders,
          totalProducts: products.length,
          activeProducts: activeProducts,
          storeRating: _store?.rating ?? 0.0,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFB45309)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFB45309),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KYC Verification Banner
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.user;
                final needsVerification =
                    user != null && user.kycStatus != 'VERIFIED';

                if (!needsVerification) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () {
                    // Navigate back to main app to access Profile/KYC page
                    Navigator.pop(context);
                    // Show message to user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Silakan lengkapi verifikasi KYC di menu AKUN',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(
                        color: const Color(0xFFB45309),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Toko Belum Terverifikasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1C1A14),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verifikasi KYC sekarang untuk meningkatkan kepercayaan pembeli',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Store Info Card
            if (_store != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFB45309),
                          width: 2,
                        ),
                      ),
                      child: _store!.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                'https://majacraft.id${_store!.logoUrl}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.store,
                                      color: Color(0xFFB45309),
                                      size: 30,
                                    ),
                              ),
                            )
                          : const Icon(
                              Icons.store,
                              color: Color(0xFFB45309),
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _store!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1A14),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _store!.province,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final isVerified =
                                  authProvider.user?.kycStatus == 'VERIFIED';
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isVerified
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isVerified
                                          ? 'Terverifikasi'
                                          : 'Belum Verifikasi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isVerified
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Stats Cards Grid
            if (_stats != null) ...[
              const Text(
                'Ringkasan Toko',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1A14),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    icon: Icons.payments,
                    title: 'Total Pendapatan',
                    value: _currencyFormat.format(_stats!.totalRevenue),
                    color: Colors.green.shade700,
                  ),
                  _buildStatCard(
                    icon: Icons.pending_actions,
                    title: 'Pesanan Aktif',
                    value: '${_stats!.activeOrders}',
                    subtitle: 'aktif',
                    color: Colors.blue.shade700,
                  ),
                  _buildStatCard(
                    icon: Icons.inventory_2,
                    title: 'Karya Terdaftar',
                    value: '${_stats!.totalProducts}',
                    subtitle: '${_stats!.activeProducts} aktif',
                    color: Colors.orange.shade700,
                  ),
                  _buildStatCard(
                    icon: Icons.star,
                    title: 'Rating Toko',
                    value: _stats!.storeRating.toStringAsFixed(1),
                    subtitle: '⭐',
                    color: Colors.amber.shade700,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1A14),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.add_circle,
                    label: 'Tambah Karya',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.shopping_bag,
                    label: 'Lihat Pesanan',
                    onTap: () {
                      widget.onGoToPesanan?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1A14),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1A10),
          border: Border.all(color: const Color(0xFFB45309).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFD4A020), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
