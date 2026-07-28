import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../screens/notification_list_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/studio/studio_screen.dart';
import 'main_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showSearch;
  final VoidCallback? onSearchTap;

  const CustomAppBar({super.key, this.showSearch = true, this.onSearchTap});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService(ApiService());
  int _unreadCount = 0;
  int _chatUnreadCount = 0;
  bool _isLoadingCount = false;
  Timer? _chatPollingTimer;
  Timer? _notifPollingTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadChatUnreadCount();
    _startChatPolling();
    _startNotifPolling();
  }

  @override
  void dispose() {
    _chatPollingTimer?.cancel();
    _notifPollingTimer?.cancel();
    super.dispose();
  }

  void _startChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadChatUnreadCount(),
    );
  }

  void _startNotifPolling() {
    _notifPollingTimer?.cancel();
    _notifPollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadUnreadCount(),
    );
  }

  Future<void> _loadChatUnreadCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null && authProvider.isAuthenticated) {
        final chats = await _chatService.getChatInbox(token: token);
        final unreadCount = _chatService.getTotalUnreadCount(chats);

        if (mounted) {
          setState(() {
            _chatUnreadCount = unreadCount;
          });
        }
      }
    } catch (_) {
      // Diam jika gagal — tidak authenticated atau network error
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoadingCount) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.token == null) return;

    setState(() => _isLoadingCount = true);

    try {
      final notifications = await _notificationService.getNotifications(
        authProvider.token!,
      );
      final unreadCount = _notificationService.getUnreadCount(notifications);

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
          _isLoadingCount = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  void _navigateToNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationListScreen()),
    );
    // Reload count after returning from notification screen
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1C1A14), // Exact website navbar color
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFF78350F,
            ).withOpacity(0.4), // amber-900/40 exact from website
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Search Field
              if (widget.showSearch)
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onSearchTap,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Color(
                          0xFF2A2620,
                        ), // Exact website search bar dark grayish-brown
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(
                            0xFF78350F,
                          ).withOpacity(0.4), // amber-900/40 from website
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Color(
                              0xFFFBBF24,
                            ), // amber-400 exact from website
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Cari kerajinan, batik, ukiran...',
                              style: TextStyle(
                                color: Color(
                                  0xFFFEF3C7,
                                ), // amber-100 exact from website
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 12),

              // Chat Icon with Badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                      // Reload count after returning from chat screen
                      _loadChatUnreadCount();
                    },
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFFFBBF24), // amber-400 exact from website
                    ),
                    iconSize: 22,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                  if (_chatUnreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(_chatUnreadCount > 9 ? 2 : 0),
                        constraints: BoxConstraints(
                          minWidth: _chatUnreadCount > 9 ? 16 : 8,
                          minHeight: _chatUnreadCount > 9 ? 16 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: _chatUnreadCount > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: _chatUnreadCount > 9
                              ? BorderRadius.circular(8)
                              : null,
                        ),
                        child: _chatUnreadCount > 9
                            ? Center(
                                child: Text(
                                  _chatUnreadCount > 99
                                      ? '99+'
                                      : _chatUnreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 4),

              // Notification Icon with Badge
              Stack(
                children: [
                  IconButton(
                    onPressed: _navigateToNotifications,
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFFFBBF24), // amber-400 exact from website
                    ),
                    iconSize: 22,
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(_unreadCount > 9 ? 2 : 0),
                        constraints: BoxConstraints(
                          minWidth: _unreadCount > 9 ? 16 : 8,
                          minHeight: _unreadCount > 9 ? 16 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: _unreadCount > 9
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: _unreadCount > 9
                              ? BorderRadius.circular(8)
                              : null,
                        ),
                        child: _unreadCount > 9
                            ? Center(
                                child: Text(
                                  _unreadCount > 99
                                      ? '99+'
                                      : _unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 4),

              // Profile Menu — hanya tampil jika sudah login
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (!auth.isAuthenticated) return const SizedBox.shrink();
                  return PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    color: const Color(0xFF1C1A15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF362215),
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFB45309),
                      child: auth.user?.image != null
                          ? ClipOval(
                              child: Image.network(
                                auth.user!.image!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        value: 'account',
                        child: _buildMenuItem(
                          Icons.person_outline,
                          'Akun Saya',
                        ),
                      ),
                      PopupMenuItem(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        value: 'orders',
                        child: _buildMenuItem(
                          Icons.receipt_long_outlined,
                          'Pesanan Saya',
                        ),
                      ),
                      PopupMenuItem(
                        height: 1,
                        padding: EdgeInsets.zero,
                        enabled: false,
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFF362215),
                        ),
                      ),
                      PopupMenuItem(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        value: 'studio',
                        child: _buildMenuItem(
                          Icons.store_outlined,
                          'Studio Seniman',
                        ),
                      ),
                      if (auth.user?.role == 'admin') ...[
                        PopupMenuItem(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          value: 'dashboard',
                          child: _buildMenuItem(
                            Icons.dashboard_outlined,
                            'Dashboard Admin',
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        height: 1,
                        padding: EdgeInsets.zero,
                        enabled: false,
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFF362215),
                        ),
                      ),
                      PopupMenuItem(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        value: 'logout',
                        child: _buildMenuItem(
                          Icons.logout,
                          'Keluar',
                          isLogout: true,
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleMenuSelection(context, value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, {bool isLogout = false}) {
    return Row(
      children: [
        Icon(
          icon,
          color: isLogout ? Colors.red.shade400 : const Color(0xFFB45309),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: isLogout ? Colors.red.shade400 : Colors.white,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'account':
        mainScreenKey.currentState?.goToProfile();
        break;
      case 'orders':
        mainScreenKey.currentState?.goToOrders();
        break;
      case 'studio':
        // Langsung navigate ke Studio tanpa delay
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudioScreen()),
        );
        break;
      case 'dashboard':
        // Ignore - admin only
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF362215), width: 1),
        ),
        title: const Text('Keluar', style: TextStyle(color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade400)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7A4822), Color(0xFF653611)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // tutup dialog
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();
                // Tidak perlu navigasi — Provider notifyListeners()
                // akan rebuild widget tree dan tampilkan kondisi not-authenticated
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );
  }
}
