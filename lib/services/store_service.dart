import '../models/store.dart';
import '../models/product.dart';
import 'api_service.dart';

class StoreService {
  final ApiService _apiService;

  StoreService(this._apiService);

  /// Get store details by slug
  Future<Store> getStoreBySlug(String slug, {String? token}) async {
    try {
      print('[StoreService] Getting store with slug: "$slug"');

      if (slug.isEmpty) {
        throw Exception('Store slug is empty!');
      }

      final response = await _apiService.get('/api/stores/$slug', token: token);

      if (response['success'] == true && response['data'] != null) {
        return Store.fromJson(response['data']);
      }

      throw Exception(response['error'] ?? 'Failed to get store details');
    } catch (e) {
      print('[StoreService] Error getting store: $e');
      rethrow;
    }
  }

  /// Get products from a specific store
  Future<Map<String, dynamic>> getStoreProducts(
    String slug, {
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String sort = 'terbaru',
    String? token,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (category != null) {
        queryParams['kategori'] = category;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      final endpoint = '/api/stores/$slug/products?$queryString';

      final response = await _apiService.get(endpoint, token: token);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        // Parse products
        final List<dynamic> productsJson = data['products'] ?? [];
        final products = productsJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        // Parse pagination
        final pagination = data['pagination'] ?? {};

        return {
          'products': products,
          'pagination': {
            'page': pagination['page'] ?? page,
            'limit': pagination['limit'] ?? limit,
            'total': pagination['total'] ?? 0,
            'totalPages': pagination['totalPages'] ?? 0,
          },
        };
      }

      throw Exception(response['error'] ?? 'Failed to get store products');
    } catch (e) {
      print('[StoreService] Error getting store products: $e');
      rethrow;
    }
  }

  /// Get store owner info for chat initiation
  Future<Map<String, String>> getStoreOwner(
    String slug, {
    String? token,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/stores/$slug/owner',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return {
          'userId': data['userId'] as String,
          'storeName': data['storeName'] as String,
        };
      }

      throw Exception(response['error'] ?? 'Failed to get store owner');
    } catch (e) {
      print('[StoreService] Error getting store owner: $e');
      rethrow;
    }
  }
}
