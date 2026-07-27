import '../models/chat.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService;

  ChatService(this._apiService);

  /// GET /api/chat - Inbox semua percakapan
  Future<List<Chat>> getChatInbox({String? token}) async {
    try {
      print('[ChatService] Getting chat inbox');

      final response = await _apiService.get('/api/chat', token: token);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data
            .map((json) => Chat.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(response['error'] ?? 'Failed to get chat inbox');
    } catch (e) {
      print('[ChatService] Error getting inbox: $e');
      rethrow;
    }
  }

  /// POST /api/chat - Buat atau temukan chat
  /// Returns chatId
  Future<String> createOrGetChat({
    required String targetUserId,
    String? productId,
    String? orderId,
    String? token,
  }) async {
    try {
      print('[ChatService] Creating/getting chat with user: $targetUserId');

      final body = {'targetUserId': targetUserId};

      if (productId != null) {
        body['productId'] = productId;
      }

      if (orderId != null) {
        body['orderId'] = orderId;
      }

      final response = await _apiService.post(
        '/api/chat',
        body: body,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final chatId = response['data']['id']?.toString();
        if (chatId != null && chatId.isNotEmpty) {
          print('[ChatService] Chat created/found: $chatId');
          return chatId;
        }
      }

      // Fallback: check if 'id' is directly in response
      if (response['id'] != null) {
        return response['id'].toString();
      }

      throw Exception(response['error'] ?? 'Failed to create/get chat');
    } catch (e) {
      print('[ChatService] Error creating/getting chat: $e');
      rethrow;
    }
  }

  /// GET /api/chat/[id]/messages - Ambil riwayat pesan
  /// Automatically marks messages as read
  Future<List<Message>> getChatMessages(String chatId, {String? token}) async {
    try {
      print('[ChatService] Getting messages for chat: $chatId');

      final response = await _apiService.get(
        '/api/chat/$chatId/messages',
        token: token,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data
            .map((json) => Message.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception(response['error'] ?? 'Failed to get messages');
    } catch (e) {
      print('[ChatService] Error getting messages: $e');
      rethrow;
    }
  }

  /// POST /api/chat/[id]/messages - Kirim pesan
  Future<Message> sendMessage(
    String chatId,
    String content, {
    String? token,
  }) async {
    try {
      print('[ChatService] Sending message to chat: $chatId');

      final response = await _apiService.post(
        '/api/chat/$chatId/messages',
        body: {'content': content},
        token: token,
      );

      // Check if message was blocked
      if (response['isBlocked'] == true) {
        throw Exception(
          response['warning'] ??
              'Pesan diblokir: tidak boleh membagikan kontak pribadi',
        );
      }

      if (response['success'] == true && response['data'] != null) {
        return Message.fromJson(response['data'] as Map<String, dynamic>);
      }

      // Some APIs might return message directly without 'data' wrapper
      if (response['id'] != null && response['content'] != null) {
        return Message.fromJson(response);
      }

      throw Exception(response['error'] ?? 'Failed to send message');
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  /// GET /api/stores/[slug]/owner - Get seller userId for chat
  Future<Map<String, String>> getStoreOwner(
    String storeSlug, {
    String? token,
  }) async {
    try {
      print('[ChatService] Getting store owner for: $storeSlug');

      final response = await _apiService.get(
        '/api/stores/$storeSlug/owner',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return {
          'userId': data['userId']?.toString() ?? '',
          'storeName': data['storeName']?.toString() ?? '',
        };
      }

      throw Exception(response['error'] ?? 'Failed to get store owner');
    } catch (e) {
      print('[ChatService] Error getting store owner: $e');
      rethrow;
    }
  }

  /// Calculate total unread count from inbox
  int getTotalUnreadCount(List<Chat> chats) {
    return chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
  }
}
