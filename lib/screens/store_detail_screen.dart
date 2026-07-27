import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/chat.dart';
import '../services/store_service.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../config/api_config.dart';
import 'chat_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final String storeSlug;
  final Store? initialStoreData;

  const StoreDetailScreen({
    super.key,
    required this.storeSlug,
    this.initialStoreData,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  Store? _store;
  List<Product> _products = [];
  bool _isLoadingStore = false;
  bool _isLoadingProducts = false;
  String? _error;

  late StoreService _storeService;
  late ChatService _chatService;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _storeService = StoreService(ApiService());
    _chatService = ChatService(ApiService());
    _store = widget.initialStoreData;

    if (_store == null) {
      _loadStore();
    }
    _loadProducts();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingProducts && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadStore() async {
    if (_isLoadingStore) return;

    setState(() {
      _isLoadingStore = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final store = await _storeService.getStoreBySlug(
        widget.storeSlug,
        token: authProvider.token,
      );

      setState(() {
        _store = store;
        _isLoadingStore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingStore = false;
      });
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoadingProducts) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMore = true;
      });
    }

    setState(() => _isLoadingProducts = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await _storeService.getStoreProducts(
        widget.storeSlug,
        page: _currentPage,
        limit: 20,
        token: authProvider.token,
      );

      final List<Product> newProducts = result['products'];
      final pagination = result['pagination'];

      setState(() {
        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        _hasMore = _currentPage < pagination['totalPages'];
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('[StoreDetail] Error loading products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    setState(() => _currentPage++);
    await _loadProducts();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      if (_store == null) _loadStore(),
      _loadProducts(refresh: true),
    ]);
  }

  void _navigateToChatWithSeller() async {
    try {
      final authProvider = context.read<AuthProvider>();

      if (!authProvider.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        return;
      }

      // Get store owner info
      final ownerInfo = await _storeService.getStoreOwner(
        widget.storeSlug,
        token: authProvider.token,
      );

      if (ownerInfo['userId']?.isEmpty ?? true) {
        throw Exception('Seller tidak ditemukan');
      }

      // Create or get chat
      final chatId = await _chatService.createOrGetChat(
        targetUserId: ownerInfo['userId']!,
        token: authProvider.token,
      );

      if (mounted) {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUser: ChatUser(
                id: ownerInfo['userId']!,
                name: ownerInfo['storeName'] ?? _store?.name ?? 'Seniman',
                image: _store?.logoUrl,
              ),
              productName: '', // No specific product in store chat
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStore && _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStore,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_store?.name ?? 'Toko'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Store Header
            if (_store != null)
              SliverToBoxAdapter(child: _buildStoreHeader(_store!)),

            // Store Stats
            if (_store != null)
              SliverToBoxAdapter(child: _buildStoreStats(_store!)),

            // Products Grid Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Karya Toko (${_store?.productCount ?? 0})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Products Grid
            if (_products.isEmpty && _isLoadingProducts)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('Belum ada produk')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index < _products.length) {
                      return ProductCard(product: _products[index]);
                    }
                    return null;
                  }, childCount: _products.length),
                ),
              ),

            // Loading More Indicator
            if (_isLoadingProducts && _products.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // Floating Chat Button
      floatingActionButton: _store != null
          ? FloatingActionButton.extended(
              onPressed: _navigateToChatWithSeller,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Seniman'),
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildStoreHeader(Store store) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo or Initial
          if (store.logoUrl != null && store.logoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                '${ApiConfig.baseUrl}${store.logoUrl}',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildStoreInitial(store);
                },
              ),
            )
          else
            _buildStoreInitial(store),

          const SizedBox(height: 16),

          // Store Name with Verification Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                store.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (store.isVerified) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 24),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                store.location,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          // Description
          if (store.description != null && store.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              store.description!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreInitial(Store store) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF8B4513).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          store.getInitial(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreStats(Store store) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Total Karya',
            value: store.productCount.toString(),
            icon: Icons.inventory_2_outlined,
          ),
          _buildStatItem(
            label: 'Total Terjual',
            value: store.totalSold.toString(),
            icon: Icons.shopping_bag_outlined,
          ),
          _buildStatItem(
            label: 'Rating',
            value: store.rating.toStringAsFixed(1),
            icon: Icons.star_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF8B4513)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
