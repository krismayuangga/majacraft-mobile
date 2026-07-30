class StudioProduct {
  final String id;
  final String name;
  final String? description;
  final int price;
  final int? originalPrice;
  final int stock;
  final String categoryId;
  final String? categoryName;
  final int? weight; // in grams
  final int? length; // in cm
  final int? width; // in cm
  final int? height; // in cm
  final String? origin;
  final String? material;
  final String? kondisi; // "Baru" or "Bekas Layak"
  final List<String> tags;
  final List<String> imageUrls;
  final String
  status; // ACTIVE, PENDING_REVIEW, NEEDS_REVISION, INACTIVE, SOLD_OFFLINE
  final String? moderationNotes;
  final int soldCount;
  final double rating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudioProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.origin,
    this.material,
    this.kondisi,
    this.tags = const [],
    this.imageUrls = const [],
    required this.status,
    this.moderationNotes,
    this.soldCount = 0,
    this.rating = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory StudioProduct.fromJson(Map<String, dynamic> json) {
    // Parse images
    List<String> images = [];
    if (json['images'] is List) {
      images = (json['images'] as List)
          .map((img) {
            if (img is Map && img.containsKey('url')) {
              return img['url'].toString();
            }
            return img.toString();
          })
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['imageUrls'] is List) {
      images = (json['imageUrls'] as List)
          .map((url) => url.toString())
          .toList();
    }

    // Parse tags
    List<String> tagsList = [];
    if (json['tags'] is List) {
      tagsList = (json['tags'] as List).map((tag) => tag.toString()).toList();
    } else if (json['tags'] is String && json['tags'].isNotEmpty) {
      tagsList = (json['tags'] as String)
          .split(',')
          .map((t) => t.trim())
          .toList();
    }

    // Parse category
    final category = json['category'] as Map<String, dynamic>?;

    return StudioProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: _parseInt(json['price']),
      originalPrice: json['originalPrice'] != null
          ? _parseInt(json['originalPrice'])
          : null,
      stock: _parseInt(json['stock']),
      categoryId:
          json['categoryId']?.toString() ?? category?['id']?.toString() ?? '',
      categoryName: category?['name']?.toString(),
      weight: json['weight'] != null ? _parseInt(json['weight']) : null,
      length: json['length'] != null ? _parseInt(json['length']) : null,
      width: json['width'] != null ? _parseInt(json['width']) : null,
      height: json['height'] != null ? _parseInt(json['height']) : null,
      origin: json['origin']?.toString(),
      material: json['material']?.toString(),
      kondisi: json['kondisi']?.toString(),
      tags: tagsList,
      imageUrls: images,
      status: _deriveStatus(json),
      moderationNotes: json['moderationNotes']?.toString(),
      soldCount: _parseInt(json['soldCount']),
      rating: _parseDouble(json['rating']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'stock': stock,
      'categoryId': categoryId,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
      'origin': origin,
      'material': material,
      'kondisi': kondisi,
      'tags': tags,
      'imageUrls': imageUrls,
    };
  }

  /// Derive status dari boolean fields backend (isActive, isModerated, isSoldOffline)
  static String _deriveStatus(Map<String, dynamic> json) {
    // Jika ada field 'status' eksplisit, pakai itu
    if (json['status'] != null) return json['status'].toString();

    final isActive = json['isActive'] == true;
    final isSoldOffline = json['isSoldOffline'] == true;

    if (isSoldOffline) return 'SOLD_OFFLINE';
    if (!isActive) return 'INACTIVE';
    return 'ACTIVE'; // isActive=true, termasuk yang belum dimoderasi
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String get statusBadgeText {
    switch (status) {
      case 'ACTIVE':
        return 'Aktif';
      case 'PENDING_REVIEW':
        return 'Perlu Review';
      case 'NEEDS_REVISION':
        return 'Perlu Perbaikan';
      case 'INACTIVE':
        return 'Nonaktif';
      case 'SOLD_OFFLINE':
        return 'Terjual Offline';
      default:
        return status;
    }
  }

  String get statusBadgeColor {
    switch (status) {
      case 'ACTIVE':
        return 'green';
      case 'PENDING_REVIEW':
        return 'orange';
      case 'NEEDS_REVISION':
        return 'red';
      case 'INACTIVE':
        return 'gray';
      case 'SOLD_OFFLINE':
        return 'blue';
      default:
        return 'gray';
    }
  }

  String get mainImage {
    return imageUrls.isNotEmpty
        ? (imageUrls[0].startsWith('http')
              ? imageUrls[0]
              : 'https://majacraft.id${imageUrls[0]}')
        : '';
  }
}

class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }
}
