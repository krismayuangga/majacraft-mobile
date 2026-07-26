class RuangBudayaPost {
  final String id;
  final String type; // ARTIKEL, CERITA_KARYA, ACARA
  final String title;
  final String slug;
  final String excerpt;
  final String? coverImage;
  final List<String> tags;
  final DateTime publishedAt;
  final int viewCount;
  final String? eventDate;
  final String? eventLocation;
  final int? eventMaxRsvp;
  final Author? author;
  final LinkedProduct? product;
  final int rsvpCount;

  RuangBudayaPost({
    required this.id,
    required this.type,
    required this.title,
    required this.slug,
    required this.excerpt,
    this.coverImage,
    required this.tags,
    required this.publishedAt,
    required this.viewCount,
    this.eventDate,
    this.eventLocation,
    this.eventMaxRsvp,
    this.author,
    this.product,
    required this.rsvpCount,
  });

  factory RuangBudayaPost.fromJson(Map<String, dynamic> json) {
    return RuangBudayaPost(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      excerpt: json['excerpt'] as String,
      coverImage: json['coverImage'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      viewCount: json['viewCount'] as int,
      eventDate: json['eventDate'] as String?,
      eventLocation: json['eventLocation'] as String?,
      eventMaxRsvp: json['eventMaxRsvp'] as int?,
      author: json['author'] != null
          ? Author.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? LinkedProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      rsvpCount:
          (json['_count'] as Map<String, dynamic>?)?['rsvps'] as int? ?? 0,
    );
  }

  // Helper to get display type in Indonesian
  String get typeDisplay {
    switch (type) {
      case 'ARTIKEL':
        return 'Artikel';
      case 'CERITA_KARYA':
        return 'Cerita Karya';
      case 'ACARA':
        return 'Acara';
      default:
        return type;
    }
  }

  // Helper to check if this is an event
  bool get isEvent => type == 'ACARA';

  // Helper to format event date
  String? get formattedEventDate {
    if (eventDate == null) return null;
    try {
      final date = DateTime.parse(eventDate!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return eventDate;
    }
  }
}

class Author {
  final String name;
  final String? image;

  Author({required this.name, this.image});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] as String,
      image: json['image'] as String?,
    );
  }
}

class LinkedProduct {
  final String name;
  final String slug;
  final List<ProductImage> images;

  LinkedProduct({required this.name, required this.slug, required this.images});

  factory LinkedProduct.fromJson(Map<String, dynamic> json) {
    return LinkedProduct(
      name: json['name'] as String,
      slug: json['slug'] as String,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String? get firstImageUrl => images.isNotEmpty ? images.first.url : null;
}

class ProductImage {
  final String url;

  ProductImage({required this.url});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json['url'] as String);
  }
}
