import 'dart:convert';
import '../models/wishlist.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class WishlistService {
  final ApiService _apiService = ApiService();

  /// Get all wishlist items
  Future<List<Wishlist>> getWishlists(String token) async {
    try {
      final response = await _apiService.get('/api/wishlist', token: token);

      if (response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Wishlist.fromJson(item))
            .toList();
      }

      return [];
    } catch (e) {
      print('[WishlistService] Error getting wishlists: $e');
      rethrow;
    }
  }

  /// Add product to wishlist
  Future<Wishlist> addToWishlist(String productId, String token) async {
    try {
      final response = await _apiService.post(
        '/api/wishlist',
        body: {'productId': productId},
        token: token,
      );

      return Wishlist.fromJson(response['data']);
    } catch (e) {
      print('[WishlistService] Error adding to wishlist: $e');
      rethrow;
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId, String token) async {
    try {
      await _apiService.delete('/api/wishlist/$productId', token: token);
    } catch (e) {
      print('[WishlistService] Error removing from wishlist: $e');
      rethrow;
    }
  }

  /// Check if product is wishlisted
  Future<bool> isWishlisted(String productId, String token) async {
    try {
      final response = await _apiService.get(
        '/api/wishlist/$productId',
        token: token,
      );

      return response['isWishlisted'] ?? false;
    } catch (e) {
      print('[WishlistService] Error checking wishlist: $e');
      return false;
    }
  }
}
