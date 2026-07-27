import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String? image;
  final String? phone;
  final String role;
  final String? kycStatus;
  final int? orderCount;
  final int? reviewCount;
  final int? wishlistCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.image,
    this.phone,
    required this.role,
    this.kycStatus,
    this.orderCount,
    this.reviewCount,
    this.wishlistCount,
  });

  // From JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Extract stats from _count if available
    final count = json['_count'] as Map<String, dynamic>?;

    // Fix relative image URL — tambah domain jika belum ada
    String? imageUrl = json['image'];
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = 'https://majacraft.id$imageUrl';
    }

    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      image: imageUrl,
      phone: json['phone'],
      role: json['role'] ?? 'buyer',
      kycStatus: json['kycStatus'],
      orderCount: count?['orders'] ?? json['orderCount'] ?? 0,
      reviewCount: count?['reviews'] ?? json['reviewCount'] ?? 0,
      wishlistCount: count?['wishlists'] ?? json['wishlistCount'] ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'phone': phone,
      'role': role,
      'kycStatus': kycStatus,
      'orderCount': orderCount,
      'reviewCount': reviewCount,
      'wishlistCount': wishlistCount,
    };
  }

  // To String (for storage)
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // From String
  static User fromJsonString(String jsonString) {
    return User.fromJson(jsonDecode(jsonString));
  }
}
