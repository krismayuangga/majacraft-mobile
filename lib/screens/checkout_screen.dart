import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/address_service.dart';
import '../services/api_service.dart';
import '../screens/address_form_screen.dart';
import '../screens/payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartService = CartService(ApiService());
  final _orderService = OrderService(ApiService());
  final _addressService = AddressService();
  final _noteController = TextEditingController();

  // State
  bool _loadingAddresses = true;
  bool _loadingShipping = false;
  bool _isPlacingOrder = false;

  List<Address> _addresses = [];
  Address? _selectedAddress;
  ShippingData? _shippingData;
  ShippingOption? _selectedShipping;

  String? _addressError;
  String? _shippingError;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ─── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      final addresses = await _addressService.getAddresses(token);

      setState(() {
        _addresses = addresses;
        _loadingAddresses = false;
        // Auto-select default address
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _fetchShipping();
        }
      });
    } catch (e) {
      setState(() {
        _addressError = e.toString();
        _loadingAddresses = false;
      });
    }
  }

  Future<void> _fetchShipping() async {
    if (_selectedAddress == null) return;

    setState(() {
      _loadingShipping = true;
      _shippingError = null;
      _shippingData = null;
      _selectedShipping = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      final data = await _cartService.calculateShipping(
        addressId: _selectedAddress!.id,
        token: token,
      );

      setState(() {
        _shippingData = data;
        _loadingShipping = false;
        // Auto-select cheapest courier
        if (data.couriers.isNotEmpty) {
          _selectedShipping = data.couriers.reduce(
            (a, b) => a.cost <= b.cost ? a : b,
          );
        }
      });
    } catch (e) {
      setState(() {
        _shippingError = e.toString().replaceAll('Exception: ', '');
        _loadingShipping = false;
      });
    }
  }

  void _selectAddress(Address address) {
    setState(() {
      _selectedAddress = address;
      _shippingData = null;
      _selectedShipping = null;
    });
    Navigator.pop(context); // close address bottom sheet
    _fetchShipping();
  }

  // ─── Checkout ───────────────────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _showError('Pilih alamat pengiriman terlebih dahulu');
      return;
    }
    if (_selectedShipping == null) {
      _showError('Pilih kurir pengiriman terlebih dahulu');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final token = context.read<AuthProvider>().token!;

      // Step 1: Create order
      final order = await _orderService.createOrder(
        addressId: _selectedAddress!.id,
        courierName: _selectedShipping!.courier,
        courierService: _selectedShipping!.service,
        shippingCost: _selectedShipping!.cost,
        items: widget.selectedItems
            .map((item) => {'productId': item.productId, 'qty': item.quantity})
            .toList(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        token: token,
      );

      // Step 2: Create payment URL
      final payment = await _orderService.createPayment(order.id, token: token);

      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      // Step 3: Open payment webview
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: payment.url,
            orderId: order.id,
            orderNumber: order.orderNumber,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ─── Bottom Sheet: Pilih Alamat ──────────────────────────────────────────────

  void _showAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Pilih Alamat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressFormScreen(),
                            ),
                          );
                          _loadAddresses();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF653611),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Address list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final addr = _addresses[index];
                      final isSelected = addr.id == _selectedAddress?.id;
                      return InkWell(
                        onTap: () => _selectAddress(addr),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF653611)
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? const Color(0xFF653611)
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          addr.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (addr.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF653611,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Utama',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF653611),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      addr.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (addr.phone.isNotEmpty)
                                      Text(
                                        addr.phone,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${addr.address}, ${addr.city}, ${addr.province} ${addr.zip}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  int get _subtotal =>
      widget.selectedItems.fold(0, (sum, i) => sum + i.subtotal);

  int get _total => _subtotal + (_selectedShipping?.cost ?? 0);

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                  const SizedBox(height: 16),
                  _buildShippingSection(),
                  const SizedBox(height: 16),
                  _buildNoteSection(),
                  const SizedBox(height: 16),
                  _buildSummarySection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Section Widgets ──────────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return _SectionCard(
      title: 'Alamat Pengiriman',
      icon: Icons.location_on_outlined,
      child: _selectedAddress == null
          ? _addresses.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Belum ada alamat pengiriman',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddressFormScreen(),
                            ),
                          );
                          _loadAddresses();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Alamat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF653611),
                          side: const BorderSide(color: Color(0xFF653611)),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink()
          : InkWell(
              onTap: _showAddressSheet,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedAddress!.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_selectedAddress!.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF653611,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Utama',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF653611),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedAddress!.name}  ${_selectedAddress!.phone}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.province} ${_selectedAddress!.zip}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
    );
  }

  Widget _buildItemsSection() {
    return _SectionCard(
      title: '${widget.selectedItems.length} Produk',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        children: widget.selectedItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.productImage.startsWith('http')
                        ? item.productImage
                        : 'https://majacraft.id${item.productImage}',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        '${_formatRupiah(item.price)}  ×  ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatRupiah(item.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShippingSection() {
    return _SectionCard(
      title: 'Kurir Pengiriman',
      icon: Icons.local_shipping_outlined,
      child: _selectedAddress == null
          ? const Text(
              'Pilih alamat terlebih dahulu',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : _loadingShipping
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Menghitung ongkir...', style: TextStyle(fontSize: 13)),
                ],
              ),
            )
          : _shippingError != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shippingError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchShipping,
                  child: const Text('Coba Lagi'),
                ),
              ],
            )
          : _shippingData == null || _shippingData!.couriers.isEmpty
          ? const Text(
              'Tidak ada kurir tersedia',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info rute + berat
                if (_shippingData!.originCity.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_shippingData!.originCity} → ${_shippingData!.destinationCity}'
                            '  •  ${_shippingData!.weightKg.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Warning barang berat
                if (_shippingData!.isHeavyItem) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _shippingData!.heavyItemNote ??
                                'Barang berat — estimasi ongkir mungkin berbeda. Konfirmasi dengan seller.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Daftar kurir
                ..._shippingData!.couriers.map((option) {
                  final isSelected =
                      _selectedShipping?.courier == option.courier &&
                      _selectedShipping?.service == option.service;
                  final desc = option.description.isNotEmpty
                      ? option.description
                      : option.displayName;
                  return InkWell(
                    onTap: () => setState(() => _selectedShipping = option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF653611).withOpacity(0.05)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF653611)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? const Color(0xFF653611)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  option.etd == '-'
                                      ? desc
                                      : '$desc  •  ${option.etdText}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            option.cost > 0
                                ? _formatRupiah(option.cost)
                                : 'Gratis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: option.cost > 0
                                  ? const Color(0xFF653611)
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildNoteSection() {
    return _SectionCard(
      title: 'Catatan (opsional)',
      icon: Icons.note_outlined,
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: 'Mis: Tolong dikemas dengan bubble wrap',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF653611)),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
        maxLines: 3,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildSummarySection() {
    return _SectionCard(
      title: 'Ringkasan Pembayaran',
      icon: Icons.receipt_outlined,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal produk',
            value: _formatRupiah(_subtotal),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Ongkos kirim (${_selectedShipping?.displayName ?? '-'})',
            value: _selectedShipping != null
                ? _formatRupiah(_selectedShipping!.cost)
                : '-',
          ),
          const Divider(height: 20),
          _SummaryRow(
            label: 'Total',
            value: _formatRupiah(_total),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canCheckout = _selectedAddress != null && _selectedShipping != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    _formatRupiah(_total),
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
            ElevatedButton(
              onPressed: (canCheckout && !_isPlacingOrder) ? _placeOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF653611),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF653611)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1A14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            color: isBold ? Colors.black87 : Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFF653611) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
