import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';
import '../screens/payment_webview_screen.dart';
import '../screens/complain_form_screen.dart';
import '../screens/dispute_chat_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService(ApiService());

  bool _isLoading = true;
  bool _isActionLoading = false;
  Order? _order;
  TrackingData? _tracking;
  String? _error;

  Timer? _deadlineTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _deadlineTimer?.cancel();
    super.dispose();
  }

  // ─── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      final order = await _orderService.getOrderDetail(
        widget.orderId,
        token: token,
      );

      setState(() {
        _order = order;
        _isLoading = false;
      });

      // Load tracking if shipped
      if (order.status == 'SHIPPED' || order.status == 'DELIVERED') {
        _loadTracking(token);
      }

      // Start deadline timer if pending payment
      if (order.status == 'PENDING_PAYMENT') {
        _startDeadlineTimer();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTracking(String token) async {
    try {
      final tracking = await _orderService.getTracking(
        widget.orderId,
        token: token,
      );
      if (mounted) setState(() => _tracking = tracking);
    } catch (e) {
      print('[OrderDetail] Tracking error: $e');
    }
  }

  void _startDeadlineTimer() {
    _deadlineTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _payNow() async {
    setState(() => _isActionLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final payment = await _orderService.createPayment(
        widget.orderId,
        token: token,
      );

      if (!mounted) return;
      setState(() => _isActionLoading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentUrl: payment.url,
            orderId: widget.orderId,
            orderNumber: _order?.orderNumber ?? '',
          ),
        ),
      );
      _loadOrder(); // Refresh after returning
    } catch (e) {
      setState(() => _isActionLoading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penerimaan'),
        content: const Text(
          'Apakah kamu sudah menerima barang?\n\nSetelah konfirmasi, transaksi selesai dan dana dikirim ke penjual. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              'Ya, Sudah Terima',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _orderService.confirmOrder(widget.orderId, token: token);
      _showSuccess('Pesanan dikonfirmasi. Terima kasih!');
      _loadOrder();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah kamu yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isActionLoading = true);
    try {
      final token = context.read<AuthProvider>().token!;
      await _orderService.cancelOrder(widget.orderId, token: token);
      _showSuccess('Pesanan berhasil dibatalkan');
      _loadOrder();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _openComplainForm(Order order) async {
    final disputeId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ComplainFormScreen(
          orderId: order.id,
          orderNumber: order.orderNumber,
        ),
      ),
    );
    if (disputeId != null && mounted) {
      _openDisputeChat(disputeId);
      _loadOrder();
    }
  }

  void _openDisputeChat(String disputeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DisputeChatScreen(disputeId: disputeId),
      ),
    ).then((_) => _loadOrder());
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1A14),
        foregroundColor: const Color(0xFFFBBF24),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Color(0xFFFBBF24),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrder,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
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
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrder,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _order == null
          ? const SizedBox.shrink()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final hasActions =
        order.canPay ||
        order.canConfirm ||
        order.canCancel ||
        order.canComplain ||
        order.activeDispute != null;

    return Column(
      children: [
        // Scroll content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusHeader(order),
                  const SizedBox(height: 16),

                  // Payment deadline countdown (if PENDING_PAYMENT)
                  if (order.canPay && order.paymentDeadline != null) ...[
                    _buildDeadlineCountdown(order),
                    const SizedBox(height: 16),
                  ],

                  // Tracking (if SHIPPED/DELIVERED)
                  if (_tracking != null) ...[
                    _buildTrackingSection(),
                    const SizedBox(height: 16),
                  ],

                  // Order items
                  _buildItemsSection(order),
                  const SizedBox(height: 16),

                  // Shipping info
                  _buildShippingSection(order),
                  const SizedBox(height: 16),

                  // Payment summary
                  _buildPaymentSection(order),
                  const SizedBox(height: 16),

                  // Order info
                  _buildOrderInfoSection(order),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Tombol aksi fixed di bawah
        if (hasActions)
          Container(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SafeArea(
              top: false,
              child: _isActionLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildActionButtons(order),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusHeader(Order order) {
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: order.statusColorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(
                color: order.statusColorValue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          // Action buttons sudah dipindah ke bottomNavigationBar
          const SizedBox(height: 8),
          Text(
            order.orderNumber,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBarOrNull() {
    if (_order == null) return null;
    final order = _order!;
    final hasActions =
        order.canPay ||
        order.canConfirm ||
        order.canCancel ||
        order.canComplain ||
        order.activeDispute != null;
    if (!hasActions) return null;
    return _buildBottomActionBar(order);
  }

  // ─── Bottom Action Bar (fixed di bawah) ─────────────────────────────────────

  Widget _buildBottomActionBar(Order order) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
        child: _isActionLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildActionButtons(order),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Column(
      children: [
        if (order.canPay)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _payNow,
              icon: const Icon(Icons.payment),
              label: const Text('Bayar Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF653611),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (order.canConfirm) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmDelivery,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Penerimaan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        if (order.canCancel) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Batalkan Pesanan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

        // Tombol Ajukan Komplain (jika belum ada dispute aktif)
        if (order.canComplain) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openComplainForm(order),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Ajukan Komplain'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

        // Tombol Buka Room Mediasi (jika sudah ada dispute)
        if (order.activeDispute != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openDisputeChat(order.activeDispute!.id),
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(
                'Buka Room Mediasi (${order.activeDispute!.disputeNumber})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeadlineCountdown(Order order) {
    final deadline = order.paymentDeadline!;
    final remaining = deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative;

    final minutes = isExpired ? 0 : remaining.inMinutes;
    final seconds = isExpired ? 0 : remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: isExpired ? Colors.red : Colors.orange.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Batas waktu pembayaran habis' : 'Bayar sebelum',
                  style: TextStyle(
                    fontSize: 13,
                    color: isExpired ? Colors.red : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isExpired)
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: minutes < 5 ? Colors.red : Colors.orange.shade800,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection() {
    final tracking = _tracking!;
    return Container(
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
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: Color(0xFF653611),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tracking Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tracking.courierName} ${tracking.courierService}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Resi: ${tracking.trackingNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tracking.delivered
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tracking.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: tracking.delivered ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (tracking.events.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...tracking.events
                .take(3)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, right: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF653611),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.description,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                '${event.city ?? ''}  •  ${_formatDate(event.datetime)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsSection(Order order) {
    return Container(
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
              const Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: Color(0xFF653611),
              ),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} Produk',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
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
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 24,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection(Order order) {
    return Container(
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
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF653611),
              ),
              const SizedBox(width: 8),
              const Text(
                'Alamat Pengiriman',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.recipientName != null)
            Text(
              '${order.recipientName}  •  ${order.recipientPhone ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          if (order.shippingAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              order.shippingAddress!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          if (order.recipientCity != null) ...[
            const SizedBox(height: 4),
            Text(
              '${order.recipientCity}, ${order.recipientProvince ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (order.courierName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  '${order.courierName!.toUpperCase()} ${order.courierService ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (order.trackingNumber != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• ${order.trackingNumber}',
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
          ],
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.note!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Order order) {
    return Container(
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
              const Icon(
                Icons.receipt_outlined,
                size: 18,
                color: Color(0xFF653611),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rincian Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Subtotal produk',
            value: _formatRupiah(order.subtotal),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label:
                'Ongkos kirim (${order.courierName?.toUpperCase() ?? '-'} ${order.courierService ?? ''})',
            value: _formatRupiah(order.shippingCost),
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Diskon',
              value: '- ${_formatRupiah(order.discount)}',
              valueColor: Colors.green,
            ),
          ],
          const Divider(height: 20),
          _InfoRow(
            label: 'Total Pembayaran',
            value: _formatRupiah(order.total),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(Order order) {
    return Container(
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
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF653611),
              ),
              const SizedBox(width: 8),
              const Text(
                'Info Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'No. Pesanan', value: order.orderNumber),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Tanggal Pesanan',
            value: _formatDate(order.createdAt),
          ),
          if (order.paidAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Tanggal Bayar', value: _formatDate(order.paidAt!)),
          ],
          if (order.shippedAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Tanggal Dikirim',
              value: _formatDate(order.shippedAt!),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Row Widgets ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color:
                valueColor ??
                (isBold ? const Color(0xFF653611) : Colors.black87),
          ),
        ),
      ],
    );
  }
}
