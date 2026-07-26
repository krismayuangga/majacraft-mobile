import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/order.dart';
import '../order_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class StudioPesananTab extends StatefulWidget {
  const StudioPesananTab({Key? key}) : super(key: key);

  @override
  State<StudioPesananTab> createState() => _StudioPesananTabState();
}

class _StudioPesananTabState extends State<StudioPesananTab> {
  bool _isLoading = true;
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  String? _error;
  String _selectedFilter = 'ALL';

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, String>> _filterOptions = [
    {'value': 'ALL', 'label': 'Semua'},
    {'value': 'PENDING_PAYMENT', 'label': 'Belum Bayar'},
    {'value': 'PROCESSING', 'label': 'Dikemas'},
    {'value': 'SHIPPED', 'label': 'Dikirim'},
    {'value': 'COMPLETED', 'label': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService().get(
        '/api/studio/orders',
        token: authProvider.token,
      );

      if (response['success']) {
        final ordersData = response['data'] as List;
        final orders = ordersData.map((o) => Order.fromJson(o)).toList();

        setState(() {
          _orders = orders;
          _filterOrders();
          _isLoading = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Gagal memuat pesanan');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterOrders() {
    if (_selectedFilter == 'ALL') {
      _filteredOrders = List.from(_orders);
    } else {
      _filteredOrders = _orders
          .where((order) => order.status == _selectedFilter)
          .toList();
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterOrders();
    });
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
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter Chips
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final filter = _filterOptions[index];
              final isSelected = _selectedFilter == filter['value'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    _onFilterChanged(filter['value']!);
                  },
                  selectedColor: const Color(0xFFB45309),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFB45309),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFB45309)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            },
          ),
        ),

        // Order List
        Expanded(
          child: _filteredOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: const Color(0xFFB45309),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'ALL'
                ? 'Belum ada pesanan'
                : 'Tidak ada pesanan ${_filterOptions.firstWhere((f) => f['value'] == _selectedFilter)['label']?.toLowerCase()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan yang masuk akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    Color badgeColor;
    Color badgeBg;

    switch (order.statusColor) {
      case '#FF9800':
        badgeColor = Colors.orange.shade700;
        badgeBg = Colors.orange.shade50;
        break;
      case '#2196F3':
        badgeColor = Colors.blue.shade700;
        badgeBg = Colors.blue.shade50;
        break;
      case '#9C27B0':
        badgeColor = Colors.purple.shade700;
        badgeBg = Colors.purple.shade50;
        break;
      case '#4CAF50':
        badgeColor = Colors.green.shade700;
        badgeBg = Colors.green.shade50;
        break;
      case '#F44336':
        badgeColor = Colors.red.shade700;
        badgeBg = Colors.red.shade50;
        break;
      default:
        badgeColor = Colors.grey.shade700;
        badgeBg = Colors.grey.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
          if (result == true) {
            _loadOrders(); // Refresh if updated
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order number & status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1A14),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Order info
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.itemCount} item',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currencyFormat.format(order.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Buyer & address
              if (order.recipientName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.recipientName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (order.shippingAddress != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.shippingAddress!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeago.format(order.createdAt, locale: 'id'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

              // Action button for PROCESSING status
              if (order.canInputResi) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: order),
                        ),
                      );
                      if (result == true) {
                        _loadOrders();
                      }
                    },
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Input Resi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFB45309)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
