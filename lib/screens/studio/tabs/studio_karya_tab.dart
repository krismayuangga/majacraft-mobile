import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/studio_product.dart';
import '../add_product_screen.dart';
import '../edit_product_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StudioKaryaTab extends StatefulWidget {
  const StudioKaryaTab({Key? key}) : super(key: key);

  @override
  State<StudioKaryaTab> createState() => _StudioKaryaTabState();
}

class _StudioKaryaTabState extends State<StudioKaryaTab> {
  bool _isLoading = true;
  List<StudioProduct> _products = [];
  String? _error;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final token = authProvider.token;

      final response = await apiService.get('/api/studio/products', token: token);
      
      if (response['success']) {
        final productsData = response['data'] as List;
        _products = productsData.map((p) => StudioProduct.fromJson(p)).toList();
      } else {
        _error = response['error'] ?? 'Gagal memuat produk';
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

  Future<void> _deleteProduct(String productId, String productName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$productName"?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final token = authProvider.token;

      final response = await apiService.delete(
        '/api/studio/products/$productId',
        token: token,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      } else {
        throw Exception(response['error'] ?? 'Gagal menghapus produk');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsSoldOffline(String productId, String productName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Terjual Offline'),
        content: Text(
          'Tandai "$productName" sebagai terjual di luar platform?\n\nStok akan menjadi 0 dan produk akan ditandai sebagai TERJUAL.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.purple),
            child: const Text('Ya, Tandai'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final token = authProvider.token;

      final response = await apiService.post(
        '/api/studio/products/$productId/sold-offline',
        token: token,
        body: {},
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditandai sebagai terjual offline'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      } else {
        throw Exception(response['error'] ?? 'Gagal menandai produk');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFB45309),
        ),
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
              onPressed: _loadProducts,
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

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Karya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai tambah karya pertama Anda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                );
                if (result == true) {
                  _loadProducts(); // Refresh list
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Karya',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: const Color(0xFFB45309),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(StudioProduct product) {
    Color badgeColor;
    Color badgeBg;
    switch (product.statusBadgeColor) {
      case 'green':
        badgeColor = Colors.green.shade700;
        badgeBg = Colors.green.shade50;
        break;
      case 'orange':
        badgeColor = Colors.orange.shade700;
        badgeBg = Colors.orange.shade50;
        break;
      case 'red':
        badgeColor = Colors.red.shade700;
        badgeBg = Colors.red.shade50;
        break;
      case 'blue':
        badgeColor = Colors.blue.shade700;
        badgeBg = Colors.blue.shade50;
        break;
      default:
        badgeColor = Colors.grey.shade700;
        badgeBg = Colors.grey.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Product Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: product.mainImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.mainImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image, color: Colors.grey.shade400, size: 32),
                          ),
                        )
                      : Icon(Icons.image, color: Colors.grey.shade400, size: 32),
                ),
                const SizedBox(width: 12),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1A14),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Price
                      Text(
                        _currencyFormat.format(product.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Stock & Category
                      Row(
                        children: [
                          Icon(Icons.inventory_2, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product.stock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (product.categoryName != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                product.categoryName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.statusBadgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      
                      // Moderation Notes (if any)
                      if (product.moderationNotes != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.moderationNotes!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1, color: Colors.grey.shade200),
          
          // Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Lihat
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur preview coming soon'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility_outlined, size: 16, color: Colors.blue.shade600),
                    label: Text(
                      'Lihat',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                
                // Edit
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(product: product),
                        ),
                      );
                      if (result == true) {
                        _loadProducts();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFB45309)),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                
                // Jual Offline
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _markAsSoldOffline(product.id, product.name),
                    icon: Icon(Icons.store_outlined, size: 16, color: Colors.purple.shade600),
                    label: Text(
                      'Jual Offline',
                      style: TextStyle(fontSize: 11, color: Colors.purple.shade600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                
                // Hapus
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteProduct(product.id, product.name),
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade600),
                    label: Text(
                      'Hapus',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
