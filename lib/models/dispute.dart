/// Dispute Models untuk chat room komplain/mediasi

// ─── DisputeSummary — dipakai di Order model ──────────────────────────────────

class DisputeSummary {
  final String id;
  final String status;
  final String disputeNumber;
  final DateTime createdAt;

  DisputeSummary({
    required this.id,
    required this.status,
    required this.disputeNumber,
    required this.createdAt,
  });

  factory DisputeSummary.fromJson(Map<String, dynamic> json) {
    return DisputeSummary(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_SELLER',
      disputeNumber: json['disputeNumber']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Status yang masih aktif (belum selesai)
  static const _activeStatuses = [
    'PENDING_SELLER',
    'SELLER_RESPONDED',
    'IN_MEDIATION',
    'REFUND_PENDING',
    'REFUND_FAILED',
  ];

  bool get isActive => _activeStatuses.contains(status);
}

enum DisputeStatus {
  PENDING_SELLER,
  SELLER_RESPONDED,
  IN_MEDIATION,
  REFUND_PENDING,
  RESOLVED,
  CLOSED,
  CANCELLED,
}

enum DisputeReason {
  NOT_AS_DESCRIBED,
  DAMAGED,
  INCOMPLETE,
  NOT_RECEIVED,
  WRONG_ITEM,
  FAKE_PRODUCT,
  OTHER,
}

enum DisputeAction {
  REFUND_FULL,
  REFUND_PARTIAL,
  REPLACEMENT,
  RETURN_REFUND,
  REPAIR,
}

enum SenderRole { BUYER, SELLER, ADMIN }

extension DisputeStatusExtension on DisputeStatus {
  String get value {
    return toString().split('.').last;
  }

  static DisputeStatus fromString(String value) {
    return DisputeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisputeStatus.PENDING_SELLER,
    );
  }

  String get displayName {
    switch (this) {
      case DisputeStatus.PENDING_SELLER:
        return 'Menunggu Respons Penjual';
      case DisputeStatus.SELLER_RESPONDED:
        return 'Penjual Sudah Merespons';
      case DisputeStatus.IN_MEDIATION:
        return 'Dalam Mediasi Admin';
      case DisputeStatus.REFUND_PENDING:
        return 'Proses Refund';
      case DisputeStatus.RESOLVED:
        return 'Selesai';
      case DisputeStatus.CLOSED:
        return 'Ditutup';
      case DisputeStatus.CANCELLED:
        return 'Dibatalkan';
    }
  }
}

extension DisputeReasonExtension on DisputeReason {
  String get value {
    return toString().split('.').last;
  }

  static DisputeReason fromString(String value) {
    return DisputeReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisputeReason.OTHER,
    );
  }

  String get displayName {
    switch (this) {
      case DisputeReason.NOT_AS_DESCRIBED:
        return 'Tidak Sesuai Deskripsi';
      case DisputeReason.DAMAGED:
        return 'Rusak/Cacat';
      case DisputeReason.INCOMPLETE:
        return 'Tidak Lengkap';
      case DisputeReason.NOT_RECEIVED:
        return 'Tidak Diterima';
      case DisputeReason.WRONG_ITEM:
        return 'Barang Salah';
      case DisputeReason.FAKE_PRODUCT:
        return 'Produk Palsu';
      case DisputeReason.OTHER:
        return 'Lainnya';
    }
  }
}

extension DisputeActionExtension on DisputeAction {
  String get value {
    return toString().split('.').last;
  }

  static DisputeAction fromString(String value) {
    return DisputeAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DisputeAction.REFUND_FULL,
    );
  }

  String get displayName {
    switch (this) {
      case DisputeAction.REFUND_FULL:
        return 'Refund Penuh';
      case DisputeAction.REFUND_PARTIAL:
        return 'Refund Sebagian';
      case DisputeAction.REPLACEMENT:
        return 'Ganti Barang';
      case DisputeAction.RETURN_REFUND:
        return 'Retur + Refund';
      case DisputeAction.REPAIR:
        return 'Perbaikan';
    }
  }
}

extension SenderRoleExtension on SenderRole {
  String get value {
    return toString().split('.').last;
  }

  static SenderRole fromString(String value) {
    return SenderRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SenderRole.BUYER,
    );
  }

  String get displayName {
    switch (this) {
      case SenderRole.BUYER:
        return 'Pembeli';
      case SenderRole.SELLER:
        return 'Penjual';
      case SenderRole.ADMIN:
        return 'Mediator';
    }
  }
}

class DisputeUser {
  final String id;
  final String name;
  final String? image;

  DisputeUser({required this.id, required this.name, this.image});

  factory DisputeUser.fromJson(Map<String, dynamic> json) {
    return DisputeUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}

class DisputeMessage {
  final String id;
  final String disputeId;
  final String senderId;
  final SenderRole senderRole;
  final String message;
  final List<String> attachments;
  final bool isSystemMsg;
  final DateTime createdAt;
  final DisputeUser? sender;

  DisputeMessage({
    required this.id,
    required this.disputeId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    this.attachments = const [],
    this.isSystemMsg = false,
    required this.createdAt,
    this.sender,
  });

  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsList = json['attachments'];
    List<String> parsedAttachments = [];

    if (attachmentsList is List) {
      parsedAttachments = attachmentsList
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return DisputeMessage(
      id: json['id']?.toString() ?? '',
      disputeId: json['disputeId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: SenderRoleExtension.fromString(
        json['senderRole']?.toString() ?? 'BUYER',
      ),
      message: json['message']?.toString() ?? '',
      attachments: parsedAttachments,
      isSystemMsg: json['isSystemMsg'] == true,
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      sender: json['sender'] != null
          ? DisputeUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disputeId': disputeId,
      'senderId': senderId,
      'senderRole': senderRole.value,
      'message': message,
      'attachments': attachments,
      'isSystemMsg': isSystemMsg,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }
}

class DisputeTimeline {
  final String id;
  final String action;
  final String description;
  final DateTime createdAt;

  DisputeTimeline({
    required this.id,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  factory DisputeTimeline.fromJson(Map<String, dynamic> json) {
    return DisputeTimeline(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class DisputeOrder {
  final String orderNumber;
  final int total;
  final String status;
  final List<dynamic> items;

  DisputeOrder({
    required this.orderNumber,
    required this.total,
    required this.status,
    this.items = const [],
  });

  factory DisputeOrder.fromJson(Map<String, dynamic> json) {
    return DisputeOrder(
      orderNumber: json['orderNumber']?.toString() ?? '',
      total: _parseInt(json['total']),
      status: json['status']?.toString() ?? '',
      items: json['items'] is List ? json['items'] as List<dynamic> : [],
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
      'orderNumber': orderNumber,
      'total': total,
      'status': status,
      'items': items,
    };
  }
}

class Dispute {
  final String id;
  final String disputeNumber;
  final DisputeStatus status;
  final DisputeReason reason;
  final String description;
  final DisputeAction requestedAction;
  final String? resolution;
  final int? refundAmount;

  // Return tracking
  final String? returnTrackingNumber;
  final String? returnCourier;
  final DateTime? returnShippedAt;
  final DateTime? returnReceivedAt;

  // Relations
  final DisputeOrder order;
  final DisputeUser buyer;
  final DisputeUser seller;
  final DisputeUser? assignedAdmin;

  // Messages & Timeline
  final List<DisputeMessage> messages;
  final List<DisputeTimeline> timeline;

  Dispute({
    required this.id,
    required this.disputeNumber,
    required this.status,
    required this.reason,
    required this.description,
    required this.requestedAction,
    this.resolution,
    this.refundAmount,
    this.returnTrackingNumber,
    this.returnCourier,
    this.returnShippedAt,
    this.returnReceivedAt,
    required this.order,
    required this.buyer,
    required this.seller,
    this.assignedAdmin,
    this.messages = const [],
    this.timeline = const [],
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'];
    List<DisputeMessage> parsedMessages = [];
    if (messagesList is List) {
      parsedMessages = messagesList
          .map((m) => DisputeMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    final timelineList = json['timeline'];
    List<DisputeTimeline> parsedTimeline = [];
    if (timelineList is List) {
      parsedTimeline = timelineList
          .map((t) => DisputeTimeline.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Dispute(
      id: json['id']?.toString() ?? '',
      disputeNumber: json['disputeNumber']?.toString() ?? '',
      status: DisputeStatusExtension.fromString(
        json['status']?.toString() ?? 'PENDING_SELLER',
      ),
      reason: DisputeReasonExtension.fromString(
        json['reason']?.toString() ?? 'OTHER',
      ),
      description: json['description']?.toString() ?? '',
      requestedAction: DisputeActionExtension.fromString(
        json['requestedAction']?.toString() ?? 'REFUND_FULL',
      ),
      resolution: json['resolution']?.toString(),
      refundAmount: json['refundAmount'] != null
          ? _parseInt(json['refundAmount'])
          : null,
      returnTrackingNumber: json['returnTrackingNumber']?.toString(),
      returnCourier: json['returnCourier']?.toString(),
      returnShippedAt: json['returnShippedAt'] != null
          ? DateTime.parse(json['returnShippedAt'].toString())
          : null,
      returnReceivedAt: json['returnReceivedAt'] != null
          ? DateTime.parse(json['returnReceivedAt'].toString())
          : null,
      order: DisputeOrder.fromJson(json['order'] as Map<String, dynamic>),
      buyer: DisputeUser.fromJson(json['buyer'] as Map<String, dynamic>),
      seller: DisputeUser.fromJson(json['seller'] as Map<String, dynamic>),
      assignedAdmin: json['assignedAdmin'] != null
          ? DisputeUser.fromJson(json['assignedAdmin'] as Map<String, dynamic>)
          : null,
      messages: parsedMessages,
      timeline: parsedTimeline,
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
      'disputeNumber': disputeNumber,
      'status': status.value,
      'reason': reason.value,
      'description': description,
      'requestedAction': requestedAction.value,
      'resolution': resolution,
      'refundAmount': refundAmount,
      'returnTrackingNumber': returnTrackingNumber,
      'returnCourier': returnCourier,
      'returnShippedAt': returnShippedAt?.toIso8601String(),
      'returnReceivedAt': returnReceivedAt?.toIso8601String(),
      'order': order.toJson(),
      'buyer': buyer.toJson(),
      'seller': seller.toJson(),
      'assignedAdmin': assignedAdmin?.toJson(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }

  bool get hasUnresolvedReturn =>
      returnTrackingNumber != null && returnReceivedAt == null;

  bool get canEscalate => status == DisputeStatus.SELLER_RESPONDED;

  bool get isInMediation =>
      status == DisputeStatus.IN_MEDIATION ||
      status == DisputeStatus.REFUND_PENDING;

  bool get isResolved =>
      status == DisputeStatus.RESOLVED ||
      status == DisputeStatus.CLOSED ||
      status == DisputeStatus.CANCELLED;
}
