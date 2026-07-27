/// Chat Models untuk percakapan buyer-seller
class ChatUser {
  final String id;
  final String name;
  final String? image;

  ChatUser({required this.id, required this.name, this.image});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class ChatProduct {
  final String id;
  final String name;
  final String slug;
  final int price;
  final String image;

  ChatProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.image,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    return ChatProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: _parseInt(json['price']),
      image: json['image']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'price': price,
      'image': image,
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final bool isBlocked;
  final DateTime? readAt;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.isBlocked = false,
    this.readAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isBlocked: json['isBlocked'] == true,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'].toString())
          : null,
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'isBlocked': isBlocked,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isRead => readAt != null;
}

class Chat {
  final String id;
  final String? orderId;
  final String? productId;
  final String productName;
  final ChatProduct? product;
  final ChatUser otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  Chat({
    required this.id,
    this.orderId,
    this.productId,
    required this.productName,
    this.product,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      productId: json['productId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      product: json['product'] != null
          ? ChatProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      otherUser: json['otherUser'] != null
          ? ChatUser.fromJson(json['otherUser'] as Map<String, dynamic>)
          : ChatUser(id: '', name: 'Unknown'),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: _parseInt(json['unreadCount']),
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'product': product?.toJson(),
      'otherUser': otherUser.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get hasUnread => unreadCount > 0;
}
