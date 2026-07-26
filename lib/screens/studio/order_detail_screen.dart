import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberController = TextEditingController();
  final _courierNameController = TextEditingController();
  final _courierServiceController = TextEditingController();

  bool _isSubmitting = false;
  late Order _order;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _order = widget.order;

    // Initialize date formatting for Indonesian locale
    initializeDateFormatting('id_ID', null);

    // Pre-fill with existing data if available
    if (_order.trackingNumber != null) {
      _trackingNumberController.text = _order.trackingNumber!;
    }
    if (_order.courierName != null) {
      _courierNameController.text = _order.courierName!;
    }
    if (_order.courierService != null) {
      _courierServiceController.text = _order.courierService!;
    }
  }

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _courierNameController.dispose();
    _courierServiceController.dispose();
    super.dispose();
  }

  Future<void> _submitShipping() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService().post(
        '/api/studio/orders/${_order.id}/ship',
        body: {
          'trackingNumber': _trackingNumberController.text.trim().toUpperCase(),
          'courierName': _courierNameController.text.trim(),
          'courierService': _courierServiceController.text.trim().toUpperCase(),
        },
        token: authProvider.token,
      );

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Resi berhasil diinput! Pesanan sudah dikirim.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh list
        }
      } else {
        throw Exception(response['error'] ?? 'Gagal menginput resi');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeBg;

    switch (_order.statusColor) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _order.orderNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1A14),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _order.statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                    'id_ID',
                  ).format(_order.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Buyer Information
          _buildSectionHeader('Informasi Pembeli'),
          const SizedBox(height: 12),
          _buildInfoCard([
            if (_order.recipientName != null)
              _buildInfoRow(
                Icons.person_outline,
                'Nama',
                _order.recipientName!,
              ),
            if (_order.recipientPhone != null)
              _buildInfoRow(
                Icons.phone_outlined,
                'Telepon',
                _order.recipientPhone!,
              ),
            if (_order.shippingAddress != null)
              _buildInfoRow(
                Icons.location_on_outlined,
                'Alamat',
                _order.shippingAddress!,
                multiline: true,
              ),
          ]),

          const SizedBox(height: 24),

          // Items
          _buildSectionHeader('Produk Pesanan'),
          const SizedBox(height: 12),
          ..._order.items.map((item) => _buildProductItem(item)).toList(),

          const SizedBox(height: 24),

          // Payment Summary
          _buildSectionHeader('Ringkasan Pembayaran'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildPaymentRow('Subtotal', _order.subtotal),
            _buildPaymentRow('Ongkir', _order.shippingCost),
            const Divider(height: 24),
            _buildPaymentRow('Total', _order.total, isTotal: true),
          ]),

          const SizedBox(height: 24),

          // Shipping Info
          if (_order.trackingNumber != null || _order.canInputResi) ...[
            _buildSectionHeader('Informasi Pengiriman'),
            const SizedBox(height: 12),

            if (_order.trackingNumber != null) ...[
              _buildInfoCard([
                _buildInfoRow(
                  Icons.local_shipping_outlined,
                  'Kurir',
                  '${_order.courierName} - ${_order.courierService}',
                ),
                _buildInfoRow(
                  Icons.tag,
                  'No. Resi',
                  _order.trackingNumber!,
                  copyable: true,
                ),
              ]),
            ] else if (_order.canInputResi) ...[
              _buildShippingForm(),
            ],
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1C1A14),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1A14),
                        ),
                      ),
                    ),
                    if (copyable)
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Resi disalin')),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              image: item.productImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        'https://majacraft.id${item.productImage}',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productImage.isEmpty
                ? Icon(Icons.image, color: Colors.grey.shade400)
                : null,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1A14),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x ${_currencyFormat.format(item.price)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Subtotal
          Text(
            _currencyFormat.format(item.subtotal),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? const Color(0xFF1C1A14) : Colors.grey.shade700,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: isTotal
                  ? const Color(0xFFB45309)
                  : const Color(0xFF1C1A14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Input Nomor Resi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1A14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _courierNameController,
              decoration: InputDecoration(
                labelText: 'Nama Kurir *',
                hintText: 'JNE, J&T, SiCepat, GoSend, dll',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kurir wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _courierServiceController,
              decoration: InputDecoration(
                labelText: 'Layanan *',
                hintText: 'REG, YES, OKE, dll',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Layanan kurir wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _trackingNumberController,
              decoration: InputDecoration(
                labelText: 'Nomor Resi *',
                hintText: 'Contoh: JP1234567890',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nomor resi wajib diisi';
                }
                if (value.length < 5) {
                  return 'Nomor resi terlalu pendek';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitShipping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim Pesanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
