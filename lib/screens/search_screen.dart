import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import 'products_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showSearch: true,
        onSearchTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProductsScreen()),
          );
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search Screen',
              style: TextStyle(fontSize: 24, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Product search will be available here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
