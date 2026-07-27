import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'main_screen.dart';

class CategoryGrid extends StatelessWidget {
  final VoidCallback? onViewAll;

  const CategoryGrid({super.key, this.onViewAll});

  final List<CategoryData> categories = const [
    CategoryData(
      name: 'Kerajinan Batu',
      slug: 'kerajinan-batu',
      imageUrl: 'https://majacraft.id/images/cat-batu.jpg',
    ),
    CategoryData(
      name: 'Batik & Kain',
      slug: 'batik-kain',
      imageUrl: 'https://majacraft.id/images/cat-batik.jpg',
    ),
    CategoryData(
      name: 'Ukiran Kayu',
      slug: 'ukiran-kayu',
      imageUrl: 'https://majacraft.id/images/cat-kayu.jpg',
    ),
    CategoryData(
      name: 'Perhiasan & Logam',
      slug: 'perhiasan-logam',
      imageUrl: 'https://majacraft.id/images/cat-logam.jpg',
    ),
    CategoryData(
      name: 'Fotografi',
      slug: 'fotografi',
      imageUrl: 'https://majacraft.id/images/cat-fotografi.jpg',
    ),
    CategoryData(
      name: 'Wayang & Topeng',
      slug: 'wayang-topeng',
      imageUrl: 'https://majacraft.id/images/cat-wayang.jpg',
    ),
    CategoryData(
      name: 'Keramik & Gerabah',
      slug: 'keramik-gerabah',
      imageUrl: 'https://majacraft.id/images/cat-keramik.jpg',
    ),
    CategoryData(
      name: 'Tas & Aksesoris',
      slug: 'tas-aksesoris',
      imageUrl: 'https://majacraft.id/images/cat-tas.jpg',
    ),
    CategoryData(
      name: 'Lukisan',
      slug: 'lukisan',
      imageUrl: 'https://majacraft.id/images/cat-lukisan.jpg',
    ),
    CategoryData(
      name: 'Lainnya',
      slug: 'lainnya',
      imageUrl: 'https://majacraft.id/images/cat-lainnya.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 56,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB45309),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed:
                    onViewAll ??
                    () {
                      // Fallback to mainScreenKey if callback not provided
                      mainScreenKey.currentState?.goToProducts();
                    },
                child: const Text(
                  'Lihat Semua →',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal scrollable grid (2 rows)
        SizedBox(
          height: 192,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _CategoryItem(category: categories[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryData category;

  const _CategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Switch ke tab products dengan filter kategori
        mainScreenKey.currentState?.goToProductsWithCategory(category.slug);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.brown.shade900),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.brown.shade700, Colors.brown.shade800],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CategoryData {
  final String name;
  final String slug;
  final String imageUrl;

  const CategoryData({
    required this.name,
    required this.slug,
    required this.imageUrl,
  });
}
