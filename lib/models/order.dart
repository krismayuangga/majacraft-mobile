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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem> items;
  final String? trackingNumber;
  final String? courierName;
  final String? courierService;
  final String? shippingAddress;
  final String? recipientName;
  final String? recipientPhone;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.shippingCost,
    required this.createdAt,
    this.updatedAt,
    required this.items,
    this.trackingNumber,
    this.courierName,
    this.courierService,
    this.shippingAddress,
    this.recipientName,
    this.recipientPhone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    final address = json['shippingAddress'] ?? {};

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_PAYMENT',
      total: json['total'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
      shippingCost: json['shippingCost'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      items: items.map((item) => OrderItem.fromJson(item)).toList(),
      trackingNumber: json['trackingNumber']?.toString(),
      courierName: json['courierName']?.toString(),
      courierService: json['courierService']?.toString(),
      shippingAddress:
          address['fullAddress']?.toString() ??
          json['shippingAddress']?.toString(),
      recipientName: address['name']?.toString(),
      recipientPhone: address['phone']?.toString(),
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

  String get statusColor {
    switch (status) {
      case 'PENDING_PAYMENT':
        return '#FF9800'; // Orange
      case 'PROCESSING':
        return '#2196F3'; // Blue
      case 'SHIPPED':
        return '#9C27B0'; // Purple
      case 'DELIVERED':
        return '#4CAF50'; // Green
      case 'COMPLETED':
        return '#4CAF50'; // Green
      case 'CANCELLED':
        return '#F44336'; // Red
      case 'REFUNDED':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Seller-specific helpers
  bool get canInputResi => status == 'PROCESSING';

  bool get isActive =>
      status == 'PROCESSING' || status == 'SHIPPED' || status == 'DELIVERED';
}
