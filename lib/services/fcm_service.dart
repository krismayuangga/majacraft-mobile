import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service untuk mengelola Firebase Cloud Messaging (Push Notifications)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
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
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    // Show local notification when app is in foreground
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
          icon: '@mipmap/ic_launcher',
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

  /// Handle notification tap (navigation)
  void _handleNotificationTap(RemoteMessage message) {
    print('[FCM] Notification tapped: ${message.data}');

    // TODO: Navigate to appropriate screen based on notification type
    final data = message.data;
    final type = data['type'] as String?;

    switch (type) {
      case 'new_order':
        // Navigate to order detail
        final orderId = data['orderId'];
        print('[FCM] Navigate to order: $orderId');
        break;

      case 'order_status':
        // Navigate to order detail
        final orderId = data['orderId'];
        print('[FCM] Navigate to order: $orderId');
        break;

      case 'new_chat':
        // Navigate to chat
        final chatId = data['chatId'];
        print('[FCM] Navigate to chat: $chatId');
        break;

      case 'dispute_update':
        // Navigate to dispute
        final disputeId = data['disputeId'];
        print('[FCM] Navigate to dispute: $disputeId');
        break;

      case 'review_reminder':
        // Navigate to review screen
        final orderId = data['orderId'];
        print('[FCM] Navigate to review: $orderId');
        break;

      case 'system':
        // Navigate to notifications list
        print('[FCM] Navigate to notifications');
        break;

      default:
        print('[FCM] Unknown notification type: $type');
    }
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
        '/user/fcm-token',
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
      await apiService.delete('/user/fcm-token', token: authToken);

      print('[FCM] Token unregistered from backend');
    } catch (e) {
      print('[FCM] Failed to unregister token: $e');
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

  // Handle background message (e.g., update local database, show notification)
}
