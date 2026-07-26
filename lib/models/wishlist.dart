import 'product.dart';

class Wishlist {
  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;
  final Product? product; // Populated when fetching wishlist

  Wishlist({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.product,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
      // Note: product is not serialized to avoid circular reference issues
    };
  }
}
