import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../widgets/custom_app_bar.dart';
import 'auth/login_screen.dart';
import 'order_detail_screen.dart';
import 'review_form_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _error;
  String? _currentStatusFilter;

  final List<Map<String, String?>> _tabs = [
    {'label': 'Semua', 'status': null},
    {'label': 'Belum Bayar', 'status': 'PENDING_PAYMENT'},
    {'label': 'Diproses', 'status': 'PROCESSING'},
    {'label': 'Dikirim', 'status': 'SHIPPED'},
    {'label': 'Selesai', 'status': 'COMPLETED'},
    {'label': 'Dibatalkan', 'status': 'CANCELLED'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentStatusFilter = _tabs[_tabController.index]['status'];
        });
        _loadOrders();
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.isAuthenticated) {
        print('[Orders] Not authenticated, skipping load');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String endpoint = '/api/orders';
      if (_currentStatusFilter != null) {
        endpoint += '?status=$_currentStatusFilter';
      }

      print(
        '[Orders] Loading orders with token: ${authProvider.token?.substring(0, 20)}...',
      );
      final response = await ApiService().get(
        endpoint,
        token: authProvider.token,
      );

      if (response['success'] == true && response['data'] != null) {
        final ordersData = response['data'];
        List<Order> orders;

        if (ordersData is List) {
          orders = ordersData.map((item) => Order.fromJson(item)).toList();
        } else if (ordersData is Map && ordersData['items'] is List) {
          orders = (ordersData['items'] as List)
              .map((item) => Order.fromJson(item))
              .toList();
        } else {
          orders = [];
        }

        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Orders] Error loading orders: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            appBar: CustomAppBar(onSearchTap: () {}),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Pesanan',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan login untuk melihat pesanan',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: CustomAppBar(onSearchTap: () {}),
          body: Column(
            children: [
              // Tabs Header
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF653611),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF653611),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: _tabs.map((tab) => Tab(text: tab['label'])).toList(),
                ),
              ),

              // Orders List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Pesanan',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentStatusFilter == null
                                  ? 'Mulai berbelanja sekarang'
                                  : 'Tidak ada pesanan ${_tabs[_tabController.index]['label']?.toLowerCase()}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to products
                                // Switch to "Cari" tab
                              },
                              icon: const Icon(Icons.shopping_bag_outlined),
                              label: const Text('Mulai Belanja'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF653611),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _OrderCard(order: _orders[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  Color _getStatusColor() {
    final colorHex = order.statusColor.replaceAll('#', '');
    return Color(int.parse('FF$colorHex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 16,
                          color: Color(0xFF653611),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF653611),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Product Items Preview
              ...order.items
                  .take(2)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.productImage.isNotEmpty
                                ? Image.network(
                                    item.productImage.startsWith('http')
                                        ? item.productImage
                                        : 'https://majacraft.id${item.productImage}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} item × Rp${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              // More items indicator
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${order.items.length - 2} produk lainnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Total and Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Belanja',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp${order.total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF653611),
                        ),
                      ),
                    ],
                  ),

                  // Action buttons based on status
                  _buildActionButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    void goToDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      );
    }

    switch (order.status) {
      case 'PENDING_PAYMENT':
        return ElevatedButton(
          onPressed: goToDetail,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF653611),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Bayar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

      case 'SHIPPED':
        return OutlinedButton(
          onPressed: goToDetail,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF653611),
            side: const BorderSide(color: Color(0xFF653611)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Lacak',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

      case 'DELIVERED':
        return ElevatedButton(
          onPressed: goToDetail,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Terima',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

      case 'COMPLETED':
        final unreviewed = order.unreviewedItems;
        if (unreviewed.isEmpty) {
          return OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.star, size: 16, color: Colors.green),
            label: const Text('Sudah Diulas', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }
        return OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewFormScreen(
                  orderId: order.id,
                  item: unreviewed.first,
                  onSuccess: () {},
                ),
              ),
            );
          },
          icon: const Icon(Icons.star_border, size: 16),
          label: Text(
            unreviewed.length > 1
                ? 'Beri Ulasan (${unreviewed.length})'
                : 'Beri Ulasan',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF653611),
            side: const BorderSide(color: Color(0xFF653611)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
