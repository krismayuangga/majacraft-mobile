import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_screen.dart';
import 'chat_list_screen.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    // Gunakan addPostFrameCallback agar context sudah fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final notifications = await _notificationService.getNotifications(token);

      setState(() {
        _notifications = notifications;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat notifikasi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      // Chat hanya tampil di tab Chat — filter dari halaman notifikasi
      final nonChat = _notifications
          .where((n) => n.type != NotificationType.newChat)
          .toList();
      _filteredNotifications = _showUnreadOnly
          ? nonChat.where((n) => !n.read).toList()
          : nonChat;
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.read) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      await _notificationService.markAsRead(notification.id, token);

      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(read: true);
          _applyFilter();
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      await _notificationService.markAllAsRead(_notifications, token);

      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(read: true))
            .toList();
        _applyFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sebagai dibaca'),
            backgroundColor: Color(0xFF653611),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menandai semua: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    _markAsRead(notification);

    // Navigate based on notification type and data
    final type = notification.type;
    final data = notification.data;

    // Check user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSeller = authProvider.user?.role == 'seller';

    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderStatus:
        // For sellers: navigate to Studio Pesanan tab
        // For buyers: navigate to Orders tab
        Navigator.of(context).pop();
        if (isSeller) {
          mainScreenKey.currentState?.goToStudioOrders();
        } else {
          mainScreenKey.currentState?.goToOrders();
        }
        break;

      case NotificationType.productModerated:
      case NotificationType.productRejected:
        // Pop notification screen and switch to Products tab
        Navigator.of(context).pop();
        mainScreenKey.currentState?.goToProducts();
        break;

      case NotificationType.disputeCreated:
      case NotificationType.disputeResolved:
      case NotificationType.disputeUpdate:
      case NotificationType.disputeEscalated:
        // Pop notification screen and switch to Orders tab (disputes are order-related)
        Navigator.of(context).pop();
        if (isSeller) {
          mainScreenKey.currentState?.goToStudioOrders();
        } else {
          mainScreenKey.currentState?.goToOrders();
        }
        break;

      case NotificationType.newChat:
        // Navigate to chat list screen
        Navigator.of(context).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
        break;

      case NotificationType.system:
        // System notifications don't need navigation
        break;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderStatus:
        return Icons.shopping_bag_outlined;
      case NotificationType.productModerated:
      case NotificationType.productRejected:
        return Icons.inventory_2_outlined;
      case NotificationType.disputeCreated:
      case NotificationType.disputeResolved:
      case NotificationType.disputeUpdate:
      case NotificationType.disputeEscalated:
        return Icons.gavel;
      case NotificationType.newChat:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
      case NotificationType.orderStatus:
        return const Color(0xFF653611); // Brown
      case NotificationType.productModerated:
        return Colors.green;
      case NotificationType.productRejected:
        return Colors.red;
      case NotificationType.disputeCreated:
        return Colors.orange;
      case NotificationType.disputeResolved:
        return Colors.green;
      case NotificationType.disputeUpdate:
        return Colors.purple;
      case NotificationType.disputeEscalated:
        return Colors.red;
      case NotificationType.newChat:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'id');
  }

  // Helper to enhance notification message with additional details from data
  String _getEnhancedMessage(NotificationModel notification) {
    final message = notification.message;
    final data = notification.data;

    if (data == null) return message;

    // For order notifications, try to add product details
    if (notification.type == NotificationType.newOrder) {
      final orderNumber = data['orderNumber'] as String?;
      final productNames = data['productNames'] as List?;
      final itemCount = data['itemCount'] as int?;

      if (productNames != null && productNames.isNotEmpty) {
        final firstProduct = productNames.first;
        final remaining = productNames.length - 1;

        String productInfo = firstProduct;
        if (remaining > 0) {
          productInfo += ' +$remaining produk lainnya';
        }

        return 'Ada pesanan baru senilai ${data['total'] ?? '-'}. Segera proses!\n📦 $productInfo';
      }

      if (orderNumber != null && itemCount != null) {
        return 'Ada pesanan baru $orderNumber senilai ${data['total'] ?? '-'}. $itemCount item. Segera proses!';
      }
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notificationService.getUnreadCount(_notifications);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Tandai Semua Dibaca',
                style: TextStyle(
                  color: Color(0xFF653611),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Semua',
                    count: _notifications.length,
                    isSelected: !_showUnreadOnly,
                    onTap: () {
                      setState(() {
                        _showUnreadOnly = false;
                        _applyFilter();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterChip(
                    label: 'Belum Dibaca',
                    count: unreadCount,
                    isSelected: _showUnreadOnly,
                    onTap: () {
                      setState(() {
                        _showUnreadOnly = true;
                        _applyFilter();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = _filteredNotifications[index];
                        return _NotificationCard(
                          notification: notification,
                          enhancedMessage: _getEnhancedMessage(notification),
                          icon: _getNotificationIcon(notification.type),
                          color: _getNotificationColor(notification.type),
                          timestamp: _formatTimestamp(notification.createdAt),
                          onTap: () => _handleNotificationTap(notification),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showUnreadOnly
                ? Icons.notifications_active_outlined
                : Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'Tidak ada notifikasi baru'
                : 'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'Semua notifikasi sudah dibaca'
                : 'Notifikasi Anda akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF653611) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String enhancedMessage;
  final IconData icon;
  final Color color;
  final String timestamp;
  final VoidCallback onTap;

  const _NotificationCard({
    Key? key,
    required this.notification,
    required this.enhancedMessage,
    required this.icon,
    required this.color,
    required this.timestamp,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: notification.read ? Colors.white : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.read
              ? Colors.grey[200]!
              : const Color(0xFFFFE8C5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 18),
              ),

              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: notification.read
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF653611),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enhancedMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 11,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
