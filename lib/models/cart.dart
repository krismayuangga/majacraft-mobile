class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String productSlug;
  final String productImage;
  final int price;
  final int? originalPrice;
  final int quantity; // maps from json 'qty'
  final int stock;
  final int weight; // gram, for shipping calculation
  final String? storeId;
  final String? storeName;
  final String? storeProvince;
  final bool isAvailable;
  final DateTime? addedAt; // for 20-min countdown timer

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.productImage,
    required this.price,
    this.originalPrice,
    required this.quantity,
    required this.stock,
    this.weight = 500,
    this.storeId,
    this.storeName,
    this.storeProvince,
    this.isAvailable = true,
    this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final store = product['store'] ?? {};

    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: product['name']?.toString() ?? '',
      productSlug: product['slug']?.toString() ?? '',
      productImage:
          (product['images'] is List && (product['images'] as List).isNotEmpty)
          ? (product['images'][0]['url']?.toString() ?? '')
          : '',
      price: _parseInt(product['price']),
      originalPrice: product['originalPrice'] != null
          ? _parseInt(product['originalPrice'])
          : null,
      quantity: _parseInt(json['qty'] ?? json['quantity']), // API uses 'qty'
      stock: _parseInt(product['stock']),
      weight: _parseInt(product['weight'] ?? 500),
      storeId: store['id']?.toString(),
      storeName: store['name']?.toString(),
      storeProvince: store['province']?.toString(),
      isAvailable:
          product['isActive'] != false && product['isSoldOffline'] != true,
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString())
          : null,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int get subtotal => price * quantity;

  int? get originalSubtotal =>
      originalPrice != null ? originalPrice! * quantity : null;

  int? get discount =>
      originalSubtotal != null ? originalSubtotal! - subtotal : null;

  /// Menit tersisa sebelum item expired (max 20 menit dari addedAt)
  int get minutesRemaining {
    if (addedAt == null) return 20;
    final diff = addedAt!
        .add(const Duration(minutes: 20))
        .difference(DateTime.now());
    return diff.inMinutes.clamp(0, 20);
  }

  bool get isExpired => minutesRemaining <= 0;
}

class Cart {
  final List<CartItem> items;
  final int itemCount;

  Cart({required this.items, required this.itemCount});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    return Cart(
      items: items.map((item) => CartItem.fromJson(item)).toList(),
      itemCount: items.length,
    );
  }

  int get totalPrice {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalOriginalPrice {
    return items.fold(
      0,
      (sum, item) => sum + (item.originalSubtotal ?? item.subtotal),
    );
  }

  int get totalDiscount {
    return totalOriginalPrice - totalPrice;
  }

  bool get hasDiscount {
    return totalDiscount > 0;
  }
}
