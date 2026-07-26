import 'package:flutter/foundation.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();

  List<Wishlist> _wishlists = [];
  Set<String> _wishlistedProductIds = {};
  bool _isLoading = false;
  String? _error;

  List<Wishlist> get wishlists => _wishlists;
  Set<String> get wishlistedProductIds => _wishlistedProductIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _wishlists.length;

  /// Check if a product is wishlisted
  bool isProductWishlisted(String productId) {
    return _wishlistedProductIds.contains(productId);
  }

  /// Load all wishlists
  Future<void> loadWishlists(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wishlists = await _wishlistService.getWishlists(token);
      _wishlistedProductIds = _wishlists.map((w) => w.productId).toSet();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle wishlist (add or remove)
  Future<bool> toggleWishlist(String productId, String token) async {
    final isCurrentlyWishlisted = _wishlistedProductIds.contains(productId);

    try {
      if (isCurrentlyWishlisted) {
        // Remove from wishlist
        await _wishlistService.removeFromWishlist(productId, token);

        // Optimistic update
        _wishlists.removeWhere((w) => w.productId == productId);
        _wishlistedProductIds.remove(productId);
        notifyListeners();

        return false; // Now not wishlisted
      } else {
        // Add to wishlist
        final wishlist = await _wishlistService.addToWishlist(productId, token);

        // Optimistic update
        _wishlists.add(wishlist);
        _wishlistedProductIds.add(productId);
        notifyListeners();

        return true; // Now wishlisted
      }
    } catch (e) {
      // Revert optimistic update on error
      if (isCurrentlyWishlisted) {
        _wishlistedProductIds.add(productId);
      } else {
        _wishlistedProductIds.remove(productId);
        _wishlists.removeWhere((w) => w.productId == productId);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Add to wishlist
  Future<void> addToWishlist(String productId, String token) async {
    try {
      final wishlist = await _wishlistService.addToWishlist(productId, token);
      _wishlists.add(wishlist);
      _wishlistedProductIds.add(productId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Remove from wishlist
  Future<void> removeFromWishlist(String productId, String token) async {
    try {
      await _wishlistService.removeFromWishlist(productId, token);
      _wishlists.removeWhere((w) => w.productId == productId);
      _wishlistedProductIds.remove(productId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all wishlists (e.g., on logout)
  void clearWishlists() {
    _wishlists = [];
    _wishlistedProductIds = {};
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
