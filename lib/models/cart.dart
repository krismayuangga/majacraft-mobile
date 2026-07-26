class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String productSlug;
  final String productImage;
  final int price;
  final int? originalPrice;
  final int quantity;
  final int stock;
  final String? storeId;
  final String? storeName;
  final bool isAvailable;

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
    this.storeId,
    this.storeName,
    this.isAvailable = true,
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
      price: product['price'] ?? 0,
      originalPrice: product['originalPrice'],
      quantity: json['quantity'] ?? 1,
      stock: product['stock'] ?? 0,
      storeId: store['id']?.toString(),
      storeName: store['name']?.toString(),
      isAvailable: product['isActive'] ?? true,
    );
  }

  int get subtotal => price * quantity;

  int? get originalSubtotal =>
      originalPrice != null ? originalPrice! * quantity : null;

  int? get discount =>
      originalSubtotal != null ? originalSubtotal! - subtotal : null;
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
