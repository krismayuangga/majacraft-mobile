class Product {
  final String id;
  final String name;
  final String slug;
  final int price;
  final int? originalPrice;
  final String image;
  final List<String> images;
  final String category;
  final String sellerId;
  final String sellerName;
  final String sellerLocation;
  final double sellerRating;
  final int sold;
  final double rating;
  final int reviews;
  final bool hasNFT;
  final bool isVerified;
  final bool isFeatured;
  final String? certificateId;
  final String? certificateImageUrl;
  final String? artistName;
  final String? material;
  final String? dimensions;
  final String? origin;
  final String? description;
  final int? weight;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.originalPrice,
    required this.image,
    required this.images,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
    required this.sellerRating,
    required this.sold,
    required this.rating,
    required this.reviews,
    this.hasNFT = false,
    this.isVerified = false,
    this.isFeatured = false,
    this.certificateId,
    this.certificateImageUrl,
    this.artistName,
    this.material,
    this.dimensions,
    this.origin,
    this.description,
    this.weight,
    required this.stock,
  });

  // Helper to convert relative image path to full URL
  static String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Prepend base URL for relative paths
    final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return 'https://majacraft.id$cleanPath';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle images array
    List<String> imagesList = [];
    if (json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) {
            String imgUrl = '';
            if (img is Map && img.containsKey('url')) {
              imgUrl = img['url'].toString();
            } else {
              imgUrl = img.toString();
            }
            return _getFullImageUrl(imgUrl);
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    // Fallback: if no images in array, use main image
    if (imagesList.isEmpty && json['image'] != null) {
      imagesList = [_getFullImageUrl(json['image'].toString())];
    }

    // Extract store info
    final store = json['store'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: _parseInt(json['price']),
      originalPrice: json['originalPrice'] != null
          ? _parseInt(json['originalPrice'])
          : null,
      image: imagesList.isNotEmpty ? imagesList[0] : '',
      images: imagesList,
      category: category?['slug']?.toString() ?? '',
      sellerId: store?['id']?.toString() ?? '',
      sellerName: store?['name']?.toString() ?? '',
      sellerLocation: store?['province']?.toString() ?? '',
      sellerRating: _parseDouble(store?['rating']),
      sold: _parseInt(json['soldCount']),
      rating: _parseDouble(json['rating']),
      reviews: _parseInt(json['reviewCount']),
      hasNFT: json['hasCertificate'] == true,
      isVerified: store?['isVerified'] == true,
      isFeatured: json['isFeatured'] == true,
      certificateId: json['certificateId']?.toString(),
      certificateImageUrl: json['certificateId'] != null
          ? 'https://majacraft.id/uploads/certificates/${json['certificateId']}.png'
          : null,
      artistName:
          json['artistName']?.toString() ?? store?['ownerName']?.toString(),
      material: json['material']?.toString(),
      dimensions: json['dimensions']?.toString(),
      origin: json['origin']?.toString(),
      description: json['description']?.toString(),
      weight: _parseInt(json['weight']),
      stock: _parseInt(json['stock']),
    );
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

  String get formattedPrice {
    return 'Rp${_formatNumber(price)}';
  }

  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return 'Rp${_formatNumber(originalPrice!)}';
  }

  int? get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return null;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
