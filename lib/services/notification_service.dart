import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationService {
  final http.Client _client = http.Client();

  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Get all notifications for the current user
  Future<List<NotificationModel>> getNotifications(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notifications}');
      final response = await _client.get(
        url,
        headers: _getHeaders(token: token),
      );

      print('[NotificationService] GET $url');
      print('[NotificationService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          // Handle different response formats
          List<dynamic> notificationsJson = [];
          
          final responseData = data['data'];
          
          if (responseData is List) {
            // Format: { success: true, data: [...] }
            notificationsJson = responseData;
          } else if (responseData is Map) {
            // Format: { success: true, data: { notifications: [...], unreadCount: 0 } }
            if (responseData['notifications'] != null) {
              notificationsJson = responseData['notifications'];
            } 
            // Format: { success: true, data: { items: [...], pagination: {...} } }
            else if (responseData['items'] != null) {
              notificationsJson = responseData['items'];
            }
          }
          
          print('[NotificationService] Found ${notificationsJson.length} notifications');
          
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        
        return [];
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Gagal memuat notifikasi');
      }
    } catch (e) {
      print('[NotificationService] Get notifications error: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String token) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.notificationRead(notificationId)}',
      );
      
      final response = await _client.patch(
        url,
        headers: _getHeaders(token: token),
      );

      print('[NotificationService] PATCH $url');
      print('[NotificationService] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Gagal menandai notifikasi sebagai dibaca');
      }
    } catch (e) {
      print('[NotificationService] Mark as read error: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  int getUnreadCount(List<NotificationModel> notifications) {
    return notifications.where((n) => !n.read).length;
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(List<NotificationModel> notifications, String token) async {
    final unreadNotifications = notifications.where((n) => !n.read).toList();
    
    for (final notification in unreadNotifications) {
      try {
        await markAsRead(notification.id, token);
      } catch (e) {
        print('[NotificationService] Error marking ${notification.id} as read: $e');
        // Continue marking other notifications even if one fails
      }
    }
  }
}
