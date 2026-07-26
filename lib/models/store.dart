class Store {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? phone;
  final String province;
  final String? city;
  final String? district;
  final String? village;
  final String? address;
  final String? postalCode;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;
  final double rating;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  Store({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.logoUrl,
    this.phone,
    required this.province,
    this.city,
    this.district,
    this.village,
    this.address,
    this.postalCode,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
    required this.rating,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phone: json['phone'] as String?,
      province: json['province'] as String,
      city: json['city'] as String?,
      district: json['district'] as String?,
      village: json['village'] as String?,
      address: json['address'] as String?,
      postalCode: json['postalCode'] as String?,
      bankName: json['bankName'] as String?,
      bankAccount: json['bankAccount'] as String?,
      bankHolder: json['bankHolder'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'phone': phone,
      'province': province,
      'city': city,
      'district': district,
      'village': village,
      'address': address,
      'postalCode': postalCode,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankHolder': bankHolder,
      'rating': rating,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class StudioStats {
  final double totalRevenue;
  final int activeOrders;
  final int totalProducts;
  final int activeProducts;
  final double storeRating;

  StudioStats({
    required this.totalRevenue,
    required this.activeOrders,
    required this.totalProducts,
    required this.activeProducts,
    required this.storeRating,
  });

  factory StudioStats.fromJson(Map<String, dynamic> json) {
    return StudioStats(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      activeProducts: json['activeProducts'] as int? ?? 0,
      storeRating: (json['storeRating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
