import 'package:flutter/material.dart';

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productSlug;
  final String productImage;
  final int price;
  final int quantity;
  final int subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};

    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName:
          product['name']?.toString() ?? json['productName']?.toString() ?? '',
      productSlug: product['slug']?.toString() ?? '',
      productImage:
          (product['images'] is List && (product['images'] as List).isNotEmpty)
          ? (product['images'][0]['url']?.toString() ?? '')
          : '',
      price: json['price'] ?? product['price'] ?? 0,
      quantity: json['quantity'] ?? 1,
      subtotal: json['subtotal'] ?? 0,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final int total;
  final int subtotal;
  final int shippingCost;
  final int platformFee;
  final int discount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paymentDeadline;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final String? trackingNumber;
  final String? courierName;
  final String? courierService;
  final String? note;
  final String? shippingAddress;
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientCity;
  final String? recipientProvince;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.shippingCost,
    this.platformFee = 0,
    this.discount = 0,
    required this.createdAt,
    this.updatedAt,
    this.paymentDeadline,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    required this.items,
    this.trackingNumber,
    this.courierName,
    this.courierService,
    this.note,
    this.shippingAddress,
    this.recipientName,
    this.recipientPhone,
    this.recipientCity,
    this.recipientProvince,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    // address may be object or null
    final address =
        (json['address'] is Map ? json['address'] : null) ??
        (json['shippingAddress'] is Map ? json['shippingAddress'] : null) ??
        {};

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_PAYMENT',
      total: _parseInt(json['total']),
      subtotal: _parseInt(json['subtotal']),
      shippingCost: _parseInt(json['shippingCost']),
      platformFee: _parseInt(json['platformFee']),
      discount: _parseInt(json['discount']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      paymentDeadline: _parseDate(json['paymentDeadline']),
      paidAt: _parseDate(json['paidAt']),
      shippedAt: _parseDate(json['shippedAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
      items: items.map((item) => OrderItem.fromJson(item)).toList(),
      trackingNumber: json['trackingNumber']?.toString(),
      courierName: json['courierName']?.toString(),
      courierService: json['courierService']?.toString(),
      note: json['note']?.toString(),
      shippingAddress:
          address['address']?.toString() ??
          address['fullAddress']?.toString() ??
          (json['shippingAddress'] is String
              ? json['shippingAddress']?.toString()
              : null),
      recipientName: address['name']?.toString(),
      recipientPhone: address['phone']?.toString(),
      recipientCity: address['city']?.toString(),
      recipientProvince: address['province']?.toString(),
    );
  }

  String get statusText {
    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Belum Bayar';
      case 'PROCESSING':
        return 'Dikemas';
      case 'SHIPPED':
        return 'Dikirim';
      case 'DELIVERED':
        return 'Diterima';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'REFUNDED':
        return 'Refund';
      default:
        return status;
    }
  }

  Color get statusColorValue {
    switch (status) {
      case 'PENDING_PAYMENT':
        return const Color(0xFFFF9800);
      case 'PROCESSING':
        return const Color(0xFF2196F3);
      case 'SHIPPED':
        return const Color(0xFF9C27B0);
      case 'DELIVERED':
        return const Color(0xFF4CAF50);
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      case 'REFUNDED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  // Keep for backward compat
  String get statusColor => statusColorValue.value.toRadixString(16);

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Apakah pesanan masih bisa dibayar (ada deadline)
  bool get canPay => status == 'PENDING_PAYMENT';

  /// Apakah bisa dibatalkan
  bool get canCancel => status == 'PENDING_PAYMENT';

  /// Apakah bisa konfirmasi diterima
  bool get canConfirm => status == 'DELIVERED' || status == 'SHIPPED';

  /// Seller-specific: apakah bisa input resi
  bool get canInputResi => status == 'PROCESSING';

  bool get isActive =>
      status == 'PROCESSING' || status == 'SHIPPED' || status == 'DELIVERED';

  /// Menit tersisa untuk bayar (dari paymentDeadline)
  int get minutesUntilDeadline {
    if (paymentDeadline == null) return 30;
    final diff = paymentDeadline!.difference(DateTime.now());
    return diff.inMinutes.clamp(0, 60);
  }
}
