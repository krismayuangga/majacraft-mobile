import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/dispute.dart';
import '../services/dispute_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class DisputeChatScreen extends StatefulWidget {
  final String disputeId;

  const DisputeChatScreen({super.key, required this.disputeId});

  @override
  State<DisputeChatScreen> createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  final DisputeService _disputeService = DisputeService(ApiService());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Dispute? _dispute;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;
  String? _currentUserId;
  String? _currentUserRole; // BUYER or SELLER

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _loadDispute();
    _startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDispute() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      _currentUserId = authProvider.user?.id;
      _currentUserRole = authProvider.user?.role; // Assuming role is available

      final dispute = await _disputeService.getDispute(
        widget.disputeId,
        token: token,
      );

      if (mounted) {
        setState(() {
          _dispute = dispute;
          _isLoading = false;
          _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('[DisputeChat] Error loading dispute: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startPolling() {
    // Poll setiap 5 detik sesuai dokumentasi
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadDispute();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      _messageController.clear();

      await _disputeService.sendDisputeMessage(
        widget.disputeId,
        content,
        token: token,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
        // Reload to get new message
        _loadDispute();
      }
    } catch (e) {
      print('[DisputeChat] Error sending message: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleBubbleColor(SenderRole role) {
    switch (role) {
      case SenderRole.BUYER:
        return const Color(0xFFFFA726);
      case SenderRole.SELLER:
        return const Color(0xFF42A5F5);
      case SenderRole.ADMIN:
        return const Color(0xFF66BB6A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Komplain', style: TextStyle(fontSize: 16)),
            if (_dispute != null)
              Text(
                'No. ${_dispute!.disputeNumber}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF653611),
        elevation: 1,
        actions: [
          if (_dispute != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_dispute!.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _dispute!.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_dispute != null) _buildDisputeInfo(),
          Expanded(child: _buildMessagesList()),
          if (_dispute != null && !_dispute!.isResolved) _buildActionButtons(),
          _buildInputField(),
        ],
      ),
    );
  }

  Color _getStatusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.PENDING_SELLER:
        return Colors.orange;
      case DisputeStatus.SELLER_RESPONDED:
        return Colors.blue;
      case DisputeStatus.IN_MEDIATION:
        return Colors.purple;
      case DisputeStatus.REFUND_PENDING:
        return Colors.green;
      case DisputeStatus.RESOLVED:
        return Colors.green.shade700;
      case DisputeStatus.CLOSED:
      case DisputeStatus.CANCELLED:
        return Colors.grey;
    }
  }

  Widget _buildDisputeInfo() {
    final dispute = _dispute!;
    final order = dispute.order;

    // Extract product info from first item (try multiple field paths)
    String productName = 'Produk';
    String productImageUrl = '';
    int productPrice = 0;

    if (order.items.isNotEmpty) {
      final item = order.items[0] as Map;
      productName = item['productName']?.toString() ?? 'Produk';
      productPrice = _parseItemInt(item['price']);

      // Try different image field paths
      final product = item['product'] as Map? ?? {};
      final images = product['images'] as List?;
      if (images != null && images.isNotEmpty) {
        final rawUrl = (images[0] as Map)['url']?.toString() ?? '';
        productImageUrl = rawUrl.startsWith('http')
            ? rawUrl
            : 'https://majacraft.id$rawUrl';
      } else if (product['image'] != null) {
        final rawUrl = product['image'].toString();
        productImageUrl = rawUrl.startsWith('http')
            ? rawUrl
            : 'https://majacraft.id$rawUrl';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Produk row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: productImageUrl.isNotEmpty
                    ? Image.network(
                        productImageUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesanan #${order.orderNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (order.total > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${_formatRupiah(order.total)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF653611),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Info komplain
          _buildInfoRow('Alasan', dispute.reason.displayName),
          _buildInfoRow('Permintaan', dispute.requestedAction.displayName),

          // Deskripsi
          const SizedBox(height: 8),
          Text(
            'Deskripsi:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dispute.description,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),

          // Pihak yang terlibat
          const SizedBox(height: 10),
          Row(
            children: [
              _buildParticipantChip(
                'Pembeli',
                dispute.buyer.name,
                Colors.blue.shade50,
                Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              _buildParticipantChip(
                'Penjual',
                dispute.seller.name,
                Colors.green.shade50,
                Colors.green.shade700,
              ),
              if (dispute.assignedAdmin != null) ...[
                const SizedBox(width: 8),
                _buildParticipantChip(
                  'Admin',
                  dispute.assignedAdmin!.name,
                  Colors.purple.shade50,
                  Colors.purple.shade700,
                ),
              ],
            ],
          ),

          // Foto bukti (jika ada)
          if (dispute.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Foto Bukti:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dispute.evidenceUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = dispute.evidenceUrls[i];
                  final fullUrl = url.startsWith('http')
                      ? url
                      : 'https://majacraft.id$url';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      fullUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(size: 72),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagePlaceholder({double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: size * 0.4,
      ),
    );
  }

  Widget _buildParticipantChip(String role, String name, Color bg, Color fg) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              role,
              style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                color: fg,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static int _parseItemInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatRupiah(int amount) {
    return 'Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat komplain',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDispute,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_dispute == null || _dispute!.messages.isEmpty) {
      return Center(
        child: Text(
          'Belum ada pesan',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _dispute!.messages.length,
      itemBuilder: (context, index) {
        final message = _dispute!.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(DisputeMessage message) {
    // System message
    if (message.isSystemMsg) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isMe = message.senderId == _currentUserId;
    final bubbleColor = _getRoleBubbleColor(message.senderRole);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: bubbleColor.withOpacity(0.2),
              child: Text(
                message.sender?.name?[0].toUpperCase() ?? '?',
                style: TextStyle(
                  color: bubbleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '${message.sender?.name ?? 'Pengguna'} (${message.senderRole.displayName})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(message.createdAt, locale: 'id'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final dispute = _dispute!;
    final isBuyer = _currentUserRole == 'BUYER' || _currentUserRole?.toLowerCase() == 'buyer';
    final isSeller = _currentUserRole == 'SELLER' || _currentUserRole?.toLowerCase() == 'seller';
    final orderStatus = dispute.order?.status ?? '';

    // Logika sesuai dokumentasi fitur-komplain.md
    final closedStatuses = ['RESOLVED', 'CLOSED', 'CANCELLED'];
    final isClosedDispute = closedStatuses.contains(dispute.status.name);

    // 1. BUYER: Selesaikan Pesanan — rilis dana ke seller
    final showComplete = isBuyer &&
        ['SHIPPED', 'DELIVERED'].contains(orderStatus) &&
        !isClosedDispute &&
        dispute.returnTrackingNumber == null; // sembunyikan jika sudah kirim retur

    // 2. BUYER: Form input resi retur — HANYA untuk RETURN_REFUND
    final showReturnForm = isBuyer &&
        dispute.requestedAction == DisputeAction.RETURN_REFUND &&
        dispute.returnTrackingNumber == null &&
        !['PENDING_SELLER', 'CLOSED', 'CANCELLED'].contains(dispute.status.name) &&
        orderStatus != 'REFUNDED';

    // 3. SELLER: Konfirmasi terima retur
    final showConfirmReturn = isSeller &&
        dispute.returnTrackingNumber != null &&
        dispute.returnReceivedAt == null &&
        orderStatus != 'REFUNDED';

    // 4. Eskalasi ke Admin
    final showEscalate = dispute.canEscalate &&
        (isBuyer || isSeller);

    // Jangan tampilkan apa-apa jika tidak ada tombol aktif dan tidak ada info resi
    final hasAnyAction = showComplete || showReturnForm || showConfirmReturn || showEscalate;
    final hasReturnInfo = dispute.returnTrackingNumber != null;

    if (!hasAnyAction && !hasReturnInfo) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // INFO RESI RETUR (read-only) — setelah buyer submit resi
          if (hasReturnInfo) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCA28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.local_shipping, size: 16, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    const Text('Info Resi Retur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF57F17))),
                    if (dispute.returnReceivedAt != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Diterima', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Text('Kurir: ${dispute.returnCourier ?? "-"}', style: const TextStyle(fontSize: 12)),
                  Text('Nomor Resi: ${dispute.returnTrackingNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (dispute.returnReceivedAt != null)
                    Text('Diterima: ${timeago.format(dispute.returnReceivedAt!, locale: 'id')}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // BUYER: Selesaikan Pesanan
          if (showComplete) ...[
            ElevatedButton.icon(
              onPressed: _showCompleteOrderDialog,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Selesaikan Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selesaikan pesanan untuk melepas dana ke penjual',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
          ],

          // BUYER: Input resi retur
          if (showReturnForm) ...[
            ElevatedButton.icon(
              onPressed: _showSubmitReturnDialog,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Input Resi Retur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF653611),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // SELLER: Konfirmasi terima retur
          if (showConfirmReturn) ...[
            ElevatedButton.icon(
              onPressed: _confirmReturnReceived,
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Barang Retur Diterima'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Eskalasi + Batalkan
          if (showEscalate) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showEscalateDialog,
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Eskalasi ke Admin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                if (isBuyer) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showCancelDialog,
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCompleteOrderDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: const Text(
          'Yakin selesaikan pesanan? Dana akan dilepas ke penjual dan komplain akan ditutup.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await _disputeService.confirmOrder(_dispute!.order.id, token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil diselesaikan'), backgroundColor: Colors.green),
        );
        _loadDispute();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7A4822), Color(0xFF653611)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitReturnDialog() {
    final courierController = TextEditingController();
    final trackingController = TextEditingController();
    String shippingPayer = 'BUYER';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kirim Resi Retur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courierController,
                decoration: const InputDecoration(
                  labelText: 'Kurir',
                  hintText: 'JNE, J&T, SiCepat, dll',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(labelText: 'Nomor Resi'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: shippingPayer,
                decoration: const InputDecoration(
                  labelText: 'Ongkir Ditanggung',
                ),
                items: const [
                  DropdownMenuItem(value: 'BUYER', child: Text('Pembeli')),
                  DropdownMenuItem(value: 'SELLER', child: Text('Penjual')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      shippingPayer = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (courierController.text.isEmpty ||
                    trackingController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mohon lengkapi semua field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await _disputeService.submitReturnTracking(
                    disputeId: widget.disputeId,
                    courier: courierController.text,
                    trackingNumber: trackingController.text,
                    shippingPayer: shippingPayer,
                    token: authProvider.token,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resi berhasil dikirim'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadDispute();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReturnReceived() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda sudah menerima barang retur?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Sudah'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await _disputeService.confirmReturnReceived(
          widget.disputeId,
          token: authProvider.token,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konfirmasi berhasil'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDispute();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEscalateDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eskalasi ke Admin'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan Eskalasi',
            hintText: 'Jelaskan mengapa perlu melibatkan admin',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi alasan eskalasi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await _disputeService.escalateDispute(
                  widget.disputeId,
                  reasonController.text,
                  token: authProvider.token,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Komplain berhasil dieskalasi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDispute();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Eskalasi'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Komplain'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan Pembatalan',
            hintText: 'Jelaskan mengapa ingin membatalkan',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi alasan pembatalan'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await _disputeService.cancelDispute(
                  widget.disputeId,
                  reasonController.text,
                  token: authProvider.token,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Komplain berhasil dibatalkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Back to previous screen
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }
}
