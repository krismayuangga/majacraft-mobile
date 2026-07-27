import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/cart.dart';
import '../widgets/custom_app_bar.dart';
import 'auth/login_screen.dart';
import 'products_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  Cart? _cart;
  String? _error;
  Set<String> _selectedItems = {};
  bool _selectAll = false;
  Timer? _countdownTimer; // rebuild setiap 1 detik untuk countdown
  Timer? _refreshTimer; // reload cart setiap 60 detik

  @override
  void initState() {
    super.initState();
    _loadCart();
    // Countdown: rebuild UI setiap 1 detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _cart != null && _cart!.items.isNotEmpty) {
        setState(() {});
      }
    });
    // Auto-refresh cart setiap 60 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadCart();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.isAuthenticated) {
        print('[Cart] Not authenticated, skipping load');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print(
        '[Cart] Loading cart with token: ${authProvider.token?.substring(0, 20)}...',
      );
      final response = await ApiService().get(
        '/api/cart',
        token: authProvider.token,
      );

      if (response['success'] == true && response['data'] != null) {
        final cart = Cart.fromJson(response['data']);
        setState(() {
          _cart = cart;
          _isLoading = false;
          // Auto-select semua item yang tersedia
          _selectedItems = cart.items
              .where((i) => i.isAvailable)
              .map((i) => i.id)
              .toSet();
          _selectAll = _selectedItems.length == cart.items.length;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat keranjang';
        });
      }
    } catch (e) {
      print('[Cart] Error loading cart: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQty) async {
    if (newQty < 1) return;

    try {
      final authProvider = context.read<AuthProvider>();

      await ApiService().patch(
        '/api/cart',
        body: {'cartItemId': cartItemId, 'qty': newQty},
        token: authProvider.token,
      );

      // Reload cart
      _loadCart();
    } catch (e) {
      print('[Cart] Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah jumlah'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem(String cartItemId) async {
    try {
      final authProvider = context.read<AuthProvider>();

      await ApiService().delete(
        '/api/cart',
        body: {'cartItemId': cartItemId},
        token: authProvider.token,
      );

      // Remove from selected items
      setState(() {
        _selectedItems.remove(cartItemId);
      });

      // Reload cart
      _loadCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item berhasil dihapus'),
          backgroundColor: Color(0xFF653611),
        ),
      );
    } catch (e) {
      print('[Cart] Error deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll && _cart != null) {
        _selectedItems = _cart!.items.map((item) => item.id).toSet();
      } else {
        _selectedItems.clear();
      }
    });
  }

  void _toggleSelectItem(String itemId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedItems.add(itemId);
      } else {
        _selectedItems.remove(itemId);
      }
      _selectAll =
          _cart != null && _selectedItems.length == _cart!.items.length;
    });
  }

  int _getSelectedTotal() {
    if (_cart == null) return 0;
    return _cart!.items
        .where((item) => _selectedItems.contains(item.id))
        .fold(0, (sum, item) => sum + item.subtotal);
  }

  void _checkout() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 produk untuk checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedCartItems = _cart!.items
        .where((item) => _selectedItems.contains(item.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(selectedItems: selectedCartItems),
      ),
    ).then((_) => _loadCart()); // Refresh cart after checkout
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
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan login untuk melihat keranjang',
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
          body: _isLoading
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
                        onPressed: _loadCart,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _cart == null || _cart!.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Keranjang Kosong',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada karya yang ditambahkan',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to products
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ProductsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Jelajahi Karya'),
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
              : Column(
                  children: [
                    // Header with select all
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: _toggleSelectAll,
                            activeColor: const Color(0xFF653611),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pilih Semua',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_cart!.items.length} item',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Warning banner jika ada item < 5 menit
                    Builder(
                      builder: (context) {
                        final urgentItems = _cart!.items
                            .where(
                              (i) =>
                                  i.addedAt != null && i.minutesRemaining <= 5,
                            )
                            .toList();
                        if (urgentItems.isEmpty) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: Colors.orange.shade50,
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Colors.orange.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Segera checkout! ${urgentItems.length} item akan habis dalam < 5 menit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Cart Items
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCart,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _cart!.items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _cart!.items[index];
                            return _CartItemCard(
                              item: item,
                              isSelected: _selectedItems.contains(item.id),
                              onSelectChanged: (value) =>
                                  _toggleSelectItem(item.id, value),
                              onQuantityChanged: (newQty) =>
                                  _updateQuantity(item.id, newQty),
                              onDelete: () => _deleteItem(item.id),
                            );
                          },
                        ),
                      ),
                    ),

                    // Bottom Bar with Total and Checkout
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rp${_getSelectedTotal().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF653611),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectedItems.isEmpty
                                    ? null
                                    : _checkout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF653611),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                ),
                                child: Text(
                                  'Checkout (${_selectedItems.length})',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: item.isAvailable ? onSelectChanged : null,
              activeColor: const Color(0xFF653611),
            ),

            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.productImage.startsWith('http')
                    ? item.productImage
                    : 'https://majacraft.id${item.productImage}',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Store Name
                  if (item.storeName != null)
                    Text(
                      item.storeName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Price
                  Row(
                    children: [
                      Text(
                        'Rp${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF653611),
                        ),
                      ),
                      if (item.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Rp${item.originalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    children: [
                      // Decrease
                      InkWell(
                        onTap: item.quantity > 1
                            ? () => onQuantityChanged(item.quantity - 1)
                            : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: item.quantity > 1
                                ? Colors.white
                                : Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: item.quantity > 1
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),

                      // Quantity
                      SizedBox(
                        width: 40,
                        child: Text(
                          item.quantity.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Increase
                      InkWell(
                        onTap: item.quantity < item.stock
                            ? () => onQuantityChanged(item.quantity + 1)
                            : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: item.quantity < item.stock
                                ? Colors.white
                                : Colors.grey.shade100,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: item.quantity < item.stock
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Delete Button
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade400,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  // Countdown timer (dari addedAt)
                  if (item.addedAt != null) ...[
                    const SizedBox(height: 10),
                    _CartItemTimer(item: item),
                  ],

                  // Stock warning
                  if (item.quantity >= item.stock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Stok terbatas: ${item.stock}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),

                  // Not available warning
                  if (!item.isAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Produk tidak tersedia',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart Item Timer Widget ───────────────────────────────────────────────────

class _CartItemTimer extends StatefulWidget {
  final CartItem item;
  const _CartItemTimer({required this.item});

  @override
  State<_CartItemTimer> createState() => _CartItemTimerState();
}

class _CartItemTimerState extends State<_CartItemTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expireAt = widget.item.addedAt!.add(const Duration(minutes: 20));
    final remaining = expireAt.difference(DateTime.now());
    final totalSeconds = 20 * 60;
    final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
    final progress = remainingSeconds / totalSeconds; // 1.0 → 0.0

    final mm = remaining.inMinutes.clamp(0, 20);
    final ss = remaining.inSeconds.clamp(0, 1200) % 60;
    final isExpired = remaining.isNegative;
    final isUrgent = mm <= 5 && !isExpired; // < 5 menit
    final isWarning = mm > 5 && mm <= 10; // 5-10 menit

    // Warna berdasarkan sisa waktu
    final Color timerColor = isExpired
        ? Colors.grey
        : isUrgent
        ? Colors.red.shade600
        : isWarning
        ? Colors.orange.shade700
        : Colors.green.shade700;

    final Color bgColor = isExpired
        ? Colors.grey.shade100
        : isUrgent
        ? Colors.red.shade50
        : isWarning
        ? Colors.orange.shade50
        : Colors.green.shade50;

    final String timeLabel = isExpired
        ? 'Item kedaluwarsa'
        : isUrgent
        ? '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '$mm menit ${ss.toString().padLeft(2, '0')} detik';

    final String statusLabel = isExpired
        ? 'Akan dihapus dari keranjang'
        : isUrgent
        ? 'Segera checkout!'
        : isWarning
        ? 'Jangan sampai habis'
        : 'Item aman di keranjang';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar + waktu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timerColor.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: ikon + waktu | status di bawahnya
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isExpired
                        ? Icons.timer_off_outlined
                        : isUrgent
                        ? Icons.warning_amber_rounded
                        : Icons.timer_outlined,
                    size: 15,
                    color: timerColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: timerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: timerColor,
                        fontWeight: isUrgent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isExpired ? 0 : progress,
                  minHeight: 5,
                  backgroundColor: timerColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              const SizedBox(height: 6),
              // Keterangan
              Text(
                isExpired
                    ? 'Item ini telah kedaluwarsa dan akan segera dihapus dari keranjang Anda.'
                    : 'Item di keranjang disimpan selama 20 menit. Jika tidak checkout, item akan dihapus otomatis agar pembeli lain dapat berbelanja.',
                style: TextStyle(
                  fontSize: 10,
                  color: timerColor.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
