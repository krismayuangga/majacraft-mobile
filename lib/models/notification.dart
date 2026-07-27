class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message; // Maps from 'body' in API
  final NotificationType type;
  final bool read; // Maps from 'isRead' in API
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message:
          json['body']?.toString() ??
          json['message']?.toString() ??
          '', // Backend uses 'body'
      type: NotificationType.fromString(json['type']?.toString() ?? 'system'),
      read:
          json['isRead'] == true ||
          json['read'] == true, // Backend uses 'isRead'
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': message, // Backend expects 'body'
      'type': type.value,
      'isRead': read, // Backend expects 'isRead'
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? read,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum NotificationType {
  newOrder('new_order'),
  orderStatus('order_status'),
  productModerated('product_moderated'),
  productRejected('product_rejected'),
  disputeCreated('dispute_created'),
  disputeResolved('dispute_resolved'),
  newChat('new_chat'),
  system('system');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.system,
    );
  }
}
