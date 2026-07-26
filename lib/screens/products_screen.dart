import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ProductsScreen extends StatefulWidget {
  final bool autoFocusSearch;

  const ProductsScreen({super.key, this.autoFocusSearch = false});

  @override
  State<ProductsScreen> createState() => ProductsScreenState();
}

class ProductsScreenState extends State<ProductsScreen> {
  // State variables
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalProducts = 0;

  // Filter state
  String? _selectedCategorySlug;
  String _searchQuery = '';
  String _sortBy = 'terbaru'; // terbaru, termurah, terlaris
  int? _minPrice;
  int? _maxPrice;
  bool _certifiedOnly = false;

  // UI state
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadProducts();

    // Auto focus search if requested
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  // Method untuk apply filter kategori dari luar
  void applyCategory(String categorySlug) {
    print('[ProductsScreen] applyCategory called with: $categorySlug');
    setState(() {
      _selectedCategorySlug = categorySlug;
    });
    _loadProducts(refresh: true);
  }

  // Method untuk clear filter
  void clearFilters() {
    setState(() {
      _selectedCategorySlug = null;
      _searchQuery = '';
      _searchController.clear();
      _minPrice = null;
      _maxPrice = null;
      _certifiedOnly = false;
      _sortBy = 'terbaru';
    });
    _loadProducts(refresh: true);
  }

  // Method untuk focus search dari luar
  void focusSearch() {
    print('[ProductsScreen] focusSearch called');
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await ApiService().get(
        '/api/categories',
        token: authProvider.token,
      );

      if (response['data'] != null) {
        final items = response['data'] as List;
        setState(() {
          _categories = items.map((item) => Category.fromJson(item)).toList();
        });
      }
    } catch (e) {
      print('[ProductsScreen] Error loading categories: $e');
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (_selectedCategorySlug != null) {
        queryParams['kategori'] = _selectedCategorySlug!;
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_sortBy.isNotEmpty) {
        queryParams['sort'] = _sortBy;
      }
      if (_minPrice != null) {
        queryParams['minPrice'] = _minPrice.toString();
      }
      if (_maxPrice != null) {
        queryParams['maxPrice'] = _maxPrice.toString();
      }
      if (_certifiedOnly) {
        queryParams['sertifikat'] = '1';
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await ApiService().get(
        '/api/products?$queryString',
        token: authProvider.token,
      );

      if (response['data'] != null) {
        final data = response['data'];
        final items = data['items'] as List? ?? [];
        final total = data['total'] ?? 0;

        setState(() {
          _products = items.map((item) => Product.fromJson(item)).toList();
          _totalProducts = total;
          _hasMore = _products.length < total;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ProductsScreen] Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'limit': '20',
      };

      if (_selectedCategorySlug != null) {
        queryParams['kategori'] = _selectedCategorySlug!;
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }
      if (_sortBy.isNotEmpty) {
        queryParams['sort'] = _sortBy;
      }
      if (_minPrice != null) {
        queryParams['minPrice'] = _minPrice.toString();
      }
      if (_maxPrice != null) {
        queryParams['maxPrice'] = _maxPrice.toString();
      }
      if (_certifiedOnly) {
        queryParams['sertifikat'] = '1';
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await ApiService().get(
        '/api/products?$queryString',
        token: authProvider.token,
      );

      if (response['data'] != null) {
        final data = response['data'];
        final items = data['items'] as List? ?? [];
        final total = data['total'] ?? 0;

        setState(() {
          _products.addAll(items.map((item) => Product.fromJson(item)));
          _hasMore = _products.length < total;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('[ProductsScreen] Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
    }
  }

  void _applyFilters() {
    Navigator.pop(context);
    _loadProducts(refresh: true);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategorySlug = null;
      _minPrice = null;
      _maxPrice = null;
      _certifiedOnly = false;
      _sortBy = 'terbaru';
    });
    _loadProducts(refresh: true);
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategorySlug != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_certifiedOnly) count++;
    return count;
  }

  void _showFilterBottomSheet() {
    final minPriceController = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    final maxPriceController = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategorySlug = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _certifiedOnly = false;
                              minPriceController.clear();
                              maxPriceController.clear();
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFF653611)),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected =
                              _selectedCategorySlug == category.slug;
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategorySlug = selected
                                    ? category.slug
                                    : null;
                              });
                            },
                            selectedColor: Color(0xFF653611).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF653611),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF653611)
                                  : Colors.black87,
                              fontSize: 13,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Rentang Harga
                      const Text(
                        'Rentang Harga',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Min',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setModalState(() {
                                  _minPrice = int.tryParse(
                                    value.replaceAll(',', ''),
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('—'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Max',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setModalState(() {
                                  _maxPrice = int.tryParse(
                                    value.replaceAll(',', ''),
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Sertifikat NFT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hanya Produk Bersertifikat',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _certifiedOnly,
                            onChanged: (value) {
                              setModalState(() {
                                _certifiedOnly = value;
                              });
                            },
                            activeColor: const Color(0xFF653611),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF653611),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(showSearch: false), // Hide default search
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Cari kerajinan, batik, ukiran...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Color(0xFFD4AF37)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          _loadProducts(refresh: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadProducts(refresh: true);
              },
              onChanged: (value) {
                // Optional: debounce search for real-time filtering
                // For now, wait for submit
              },
            ),
          ),

          // Toolbar (Filter, Sort)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Filter Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterBottomSheet,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.tune, size: 18),
                        if (_getActiveFilterCount() > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF653611),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _getActiveFilterCount().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: const Text('Filter', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF653611),
                      side: const BorderSide(color: Color(0xFF653611)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Sort Dropdown
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF653611)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF653611),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF653611),
                          fontSize: 13,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'terbaru',
                            child: Text('Terbaru'),
                          ),
                          DropdownMenuItem(
                            value: 'termurah',
                            child: Text('Termurah'),
                          ),
                          DropdownMenuItem(
                            value: 'termahal',
                            child: Text('Termahal'),
                          ),
                          DropdownMenuItem(
                            value: 'terlaris',
                            child: Text('Terlaris'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                            _loadProducts(refresh: true);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Count
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Text(
                'Menampilkan $_totalProducts karya',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),

          // Products Grid/List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset Filter'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ProductCard(product: _products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
