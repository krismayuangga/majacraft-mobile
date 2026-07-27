class Store {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
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
  final int totalSold;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final int? productCount;

  Store({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
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
    this.totalSold = 0,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.productCount,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user']?['id'] as String? ?? '',
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
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
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : (json['rating'] != null
                ? double.parse(json['rating'].toString())
                : 0.0),
      totalSold: json['totalSold'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      productCount: json['_count']?['products'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'slug': slug,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
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
      'totalSold': totalSold,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (productCount != null) '_count': {'products': productCount},
    };
  }

  String get location {
    if (city != null && province.isNotEmpty) {
      return '$city, $province';
    }
    return province;
  }

  String getInitial() {
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
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

// Lightweight store info (included in product responses)
class StoreInfo {
  final String id;
  final String name;
  final String slug;
  final String province;
  final bool isVerified;
  final double rating;
  final int totalSold;
  final String? logoUrl;

  StoreInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.province,
    required this.isVerified,
    required this.rating,
    required this.totalSold,
    this.logoUrl,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      province: json['province'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.parse(json['rating'].toString()),
      totalSold: json['totalSold'] as int? ?? 0,
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'province': province,
      'isVerified': isVerified,
      'rating': rating,
      'totalSold': totalSold,
      'logoUrl': logoUrl,
    };
  }

  String getInitial() {
    return name.isNotEmpty ? name[0].toUpperCase() : 'T';
  }

  String get location => province;
}
