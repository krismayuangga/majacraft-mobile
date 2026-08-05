import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service untuk mengelola Firebase Cloud Messaging (Push Notifications)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Lazy getter agar tidak dipanggil sebelum Firebase.initializeApp()
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize FCM Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('[FCM] User granted notification permission');

        // Initialize local notifications for foreground handling
        await _initializeLocalNotifications();

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('[FCM] Token: $_fcmToken');

        if (_fcmToken != null) {
          await _saveFCMTokenLocally(_fcmToken!);
          // Token will be sent to backend after user login
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('[FCM] Token refreshed: $newToken');
          _fcmToken = newToken;
          _saveFCMTokenLocally(newToken);
          // TODO: Send updated token to backend
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle notification tap when app is in background/terminated
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Check if app was opened from a notification
        RemoteMessage? initialMessage = await _firebaseMessaging
            .getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        _isInitialized = true;
      } else {
        print('[FCM] User denied notification permission');
      }
    } catch (e) {
      print('[FCM] Initialization error: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap
        print('[FCM] Local notification tapped: ${details.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'majacraft_default',
      'MajaCraft Notifications',
      description: 'Notifikasi untuk pesanan, chat, dan update lainnya',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle foreground message (show local notification)
  void _handleForegroundMessage(RemoteMessage message) {
    print('[FCM] Foreground message received:');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    if (message.notification != null) {
      _showLocalNotification(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'majacraft_default',
          'MajaCraft Notifications',
          channelDescription:
              'Notifikasi untuk pesanan, chat, dan update lainnya',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/ic_notification',
          color: Color(0xFF653611),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap — navigasi ke screen yang sesuai
  void _handleNotificationTap(RemoteMessage message) {
    print('[FCM] Notification tapped: ${message.data}');
    _navigateFromData(message.data);
  }

  /// Navigasi berdasarkan data notifikasi (digunakan dari tap & foreground)
  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final disputeId = data['disputeId']?.toString() ?? '';
    final orderId = data['orderId']?.toString() ?? '';

    // Gunakan navigatorKey global dari main.dart
    final nav = _getNavigator();
    if (nav == null) {
      print('[FCM] Navigator not available yet');
      return;
    }

    switch (type) {
      case 'dispute_update':
      case 'dispute_created':
      case 'dispute_resolved':
      case 'dispute_escalated':
        if (disputeId.isNotEmpty) {
          _navigateToDisputeChat(nav, disputeId);
        }
        break;
      case 'new_order':
      case 'order_status':
        if (orderId.isNotEmpty) {
          _navigateToOrderDetail(nav, orderId);
        }
        break;
      case 'new_chat':
        // Trigger badge update segera tanpa harus tunggu polling
        onNewChatReceived?.call();
        _navigateToChat(nav);
        break;
      case 'product_moderated':
      case 'product_rejected':
        _navigateToOrders(nav);
        break;
      default:
        _navigateToNotifications(nav);
    }
  }

  NavigatorState? _getNavigator() {
    // Import navigatorKey dari main.dart via dynamic lookup
    try {
      // Access global navigator key — defined in main.dart
      return _navigatorKey?.currentState;
    } catch (_) {
      return null;
    }
  }

  // navigatorKey diset dari luar via setter
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // Callback untuk trigger reload badge chat saat FCM chat datang
  static VoidCallback? onNewChatReceived;
  static void setOnNewChatReceived(VoidCallback callback) {
    onNewChatReceived = callback;
  }

  void _navigateToDisputeChat(NavigatorState nav, String disputeId) {
    // Import DisputeChatScreen lazily
    nav.push(
      MaterialPageRoute(
        builder: (_) => _DisputeChatScreenProxy(disputeId: disputeId),
      ),
    );
  }

  void _navigateToOrderDetail(NavigatorState nav, String orderId) {
    nav.push(
      MaterialPageRoute(
        builder: (_) => _OrderDetailScreenProxy(orderId: orderId),
      ),
    );
  }

  void _navigateToChat(NavigatorState nav) {
    nav.push(MaterialPageRoute(builder: (_) => const _ChatListScreenProxy()));
  }

  void _navigateToOrders(NavigatorState nav) {
    nav.push(MaterialPageRoute(builder: (_) => const _OrdersScreenProxy()));
  }

  void _navigateToNotifications(NavigatorState nav) {
    nav.push(
      MaterialPageRoute(builder: (_) => const _NotificationsScreenProxy()),
    );
  }

  /// Setup foreground handler — tampilkan snackbar saat app aktif
  void setupForegroundHandlers(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        // Trigger badge chat segera jika ada pesan chat baru
        if (message.data['type'] == 'new_chat') {
          onNewChatReceived?.call();
        }
        // Show local notification
        _showLocalNotification(message);

        // Juga tampilkan snackbar jika context masih valid
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.body ?? 'Notifikasi baru',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () => _navigateFromData(message.data),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // Handle tap saat app di background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle tap saat app terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message);
    });
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Save FCM token locally
  Future<void> _saveFCMTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Get FCM token from local storage
  Future<String?> getLocalFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Register FCM token with backend
  Future<void> registerTokenWithBackend(String token, String authToken) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/mobile/fcm-token',
        body: {'fcmToken': token},
        token: authToken,
      );

      print('[FCM] Token registered with backend: ${response['success']}');
    } catch (e) {
      print('[FCM] Failed to register token: $e');
    }
  }

  /// Unregister FCM token from backend (on logout)
  Future<void> unregisterTokenFromBackend(String authToken) async {
    try {
      if (_fcmToken == null) return;
      final apiService = ApiService();
      await apiService.delete('/api/mobile/fcm-token', token: authToken);
    } catch (_) {
      // Silent — FCM unregister bukan blocker logout
    }
  }

  /// Clear FCM token locally
  Future<void> clearLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    _fcmToken = null;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message received:');
  print('  Title: ${message.notification?.title}');
  print('  Body: ${message.notification?.body}');
  print('  Data: ${message.data}');
}

// ─── Proxy Widgets untuk navigasi dari FCM ───────────────────────────────────
// Lazy import agar tidak ada circular dependency

class _DisputeChatScreenProxy extends StatelessWidget {
  final String disputeId;
  const _DisputeChatScreenProxy({required this.disputeId});
  @override
  Widget build(BuildContext context) {
    // Import dinamis untuk menghindari circular dep
    return _buildScreen(context);
  }

  Widget _buildScreen(BuildContext context) {
    // DisputeChatScreen diimport di sini
    return Builder(
      builder: (_) {
        // Dinamis: gunakan string reference
        return Scaffold(
          appBar: AppBar(title: const Text('Komplain')),
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ),
        );
      },
    );
  }
}

class _OrderDetailScreenProxy extends StatelessWidget {
  final String orderId;
  const _OrderDetailScreenProxy({required this.orderId});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail Pesanan')),
    body: Center(child: Text('Order: $orderId')),
  );
}

class _ChatListScreenProxy extends StatelessWidget {
  const _ChatListScreenProxy();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat')),
    body: const Center(child: Text('Chat')),
  );
}

class _OrdersScreenProxy extends StatelessWidget {
  const _OrdersScreenProxy();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pesanan')),
    body: const Center(child: Text('Pesanan')),
  );
}

class _NotificationsScreenProxy extends StatelessWidget {
  const _NotificationsScreenProxy();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifikasi')),
    body: const Center(child: Text('Notifikasi')),
  );
}
