class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? imageUrl;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.imageUrl,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      productCount: json['_count']?['products'] ?? json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'imageUrl': imageUrl,
      'productCount': productCount,
    };
  }
}
