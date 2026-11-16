import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class CatalogPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryName;
  final String? initialQuery;

  const CatalogPage({
    super.key,
    this.initialCategory,
    this.initialCategoryName,
    this.initialQuery,
  });

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const _primary = Color(0xFF78A4CB);
  static const _primaryDark = Color(0xFF5A86AD);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<dynamic> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // Filter & Urutan
  String _selectedCategory = 'all';
  String _selectedCategoryName = 'Semua Kategori';
  String _sortBy = 'id';
  String _order = 'desc';

  final List<Map<String, String>> _sortOptions = [
    {'label': 'Terbaru', 'sortBy': 'id', 'order': 'desc'},
    {'label': 'Harga: Termurah', 'sortBy': 'price', 'order': 'asc'},
    {'label': 'Harga: Termahal', 'sortBy': 'price', 'order': 'desc'},
    {'label': 'Rating Tertinggi', 'sortBy': 'rating', 'order': 'desc'},
    {'label': 'Stok Terbanyak', 'sortBy': 'stock', 'order': 'desc'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
      _selectedCategoryName = widget.initialCategoryName ?? widget.initialCategory!;
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ApiService.getCategories(),
      ApiService.getProducts(
        q: _searchController.text,
        category: _selectedCategory,
        sortBy: _sortBy,
        order: _order,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<Map<String, dynamic>>;
      _products = results[1] as List<dynamic>;
      _isLoading = false;
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final products = await ApiService.getProducts(
      q: _searchController.text,
      category: _selectedCategory,
      sortBy: _sortBy,
      order: _order,
    );
    if (!mounted) return;
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts();
    });
  }

  void _selectCategory(String slug, String name) {
    if (_selectedCategory == slug) return;
    setState(() {
      _selectedCategory = slug;
      _selectedCategoryName = name;
    });
    _fetchProducts();
  }

  void _resetFilter() {
    setState(() {
      _selectedCategory = 'all';
      _selectedCategoryName = 'Semua Kategori';
      _sortBy = 'id';
      _order = 'desc';
      _searchController.clear();
    });
    _fetchProducts();
  }

  void _openFilterBottomSheet() {
    String tempCategory = _selectedCategory;
    String tempCategoryName = _selectedCategoryName;
    String tempSortBy = _sortBy;
    String tempOrder = _order;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Urutkan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCategory = 'all';
                            tempCategoryName = 'Semua Kategori';
                            tempSortBy = 'id';
                            tempOrder = 'desc';
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Urutkan Berdasarkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _sortOptions.map((option) {
                              final isSelected = tempSortBy == option['sortBy'] &&
                                  tempOrder == option['order'];
                              return ChoiceChip(
                                label: Text(option['label']!),
                                selected: isSelected,
                                selectedColor: _primary.withAlpha(40),
                                labelStyle: TextStyle(
                                  color: isSelected ? _primaryDark : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setModalState(() {
                                    tempSortBy = option['sortBy']!;
                                    tempOrder = option['order']!;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Filter Kategori',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RadioListTile<String>(
                            title: const Text('Semua Kategori'),
                            value: 'all',
                            groupValue: tempCategory,
                            activeColor: _primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setModalState(() {
                                tempCategory = 'all';
                                tempCategoryName = 'Semua Kategori';
                              });
                            },
                          ),
                          ..._categories.map((cat) {
                            final slug = cat['slug'] ?? '';
                            final name = cat['name'] ?? slug;
                            return RadioListTile<String>(
                              title: Text(name),
                              value: slug,
                              groupValue: tempCategory,
                              activeColor: _primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setModalState(() {
                                  tempCategory = slug;
                                  tempCategoryName = name;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedCategory = tempCategory;
                          _selectedCategoryName = tempCategoryName;
                          _sortBy = tempSortBy;
                          _order = tempOrder;
                        });
                        _fetchProducts();
                      },
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final title = item['title'] ?? 'Produk';
        final price = item['price'] ?? 0;
        final rating = item['rating'] ?? 0.0;
        final stock = item['stock'] ?? 0;
        final brand = item['brand'] ?? 'Belikita';
        final category = item['category'] ?? '-';
        final description = item['description'] ?? 'Tidak ada deskripsi.';
        final thumbnail = item['thumbnail'] as String?;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (thumbnail != null && thumbnail.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        thumbnail,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          color: Colors.grey[100],
                          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(category, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.zero,
                    ),
                    const Spacer(),
                    Text('Stok: $stock', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Brand: $brand', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[800], height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    label: const Text(
                      'Tutup',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSortLabel = _sortOptions.firstWhere(
      (opt) => opt['sortBy'] == _sortBy && opt['order'] == _order,
      orElse: () => _sortOptions.first,
    )['label']!;

    final isFiltered = _selectedCategory != 'all' || _sortBy != 'id' || _order != 'desc';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Text(
          'Katalog Produk',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded, color: Colors.white),
                if (isFiltered)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter & Urutkan',
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk, brand, dll...',
                      prefixIcon: const Icon(Icons.search, color: _primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _fetchProducts();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category Chip Bar
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: _selectedCategory == 'all',
                    selectedColor: _primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedCategory == 'all' ? Colors.white : Colors.black87,
                      fontWeight: _selectedCategory == 'all' ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (_) => _selectCategory('all', 'Semua Kategori'),
                  ),
                ),
                ..._categories.map((cat) {
                  final slug = cat['slug'] ?? '';
                  final name = cat['name'] ?? slug;
                  final isSelected = _selectedCategory == slug;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      selectedColor: _primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => _selectCategory(slug, name),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Active Filter Chips Indicator
          if (isFiltered || _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCategory != 'all')
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Kategori: $_selectedCategoryName',
                                    style: const TextStyle(fontSize: 12, color: _primaryDark),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _selectCategory('all', 'Semua Kategori'),
                                    child: const Icon(Icons.close, size: 14, color: _primaryDark),
                                  ),
                                ],
                              ),
                            ),
                          if (_sortBy != 'id' || _order != 'desc')
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Urut: $currentSortLabel',
                                    style: const TextStyle(fontSize: 12, color: _primaryDark),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _sortBy = 'id';
                                        _order = 'desc';
                                      });
                                      _fetchProducts();
                                    },
                                    child: const Icon(Icons.close, size: 14, color: _primaryDark),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilter,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),
                ],
              ),
            ),

          // Main Product Grid Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _products.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Produk tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Coba gunakan kata kunci lain atau ubah filter kategori.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _resetFilter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                ),
                                child: const Text(
                                  'Reset Filter',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final item = _products[index] as Map<String, dynamic>;
                            final title = item['title'] ?? 'Tanpa Nama';
                            final price = item['price'] ?? 0;
                            final rating = item['rating'] ?? 0.0;
                            final category = item['category'] ?? '-';
                            final thumbnail = item['thumbnail'] as String?;

                            return GestureDetector(
                              onTap: () => _showProductDetails(item),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail Gambar
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child: thumbnail != null && thumbnail.isNotEmpty
                                              ? Image.network(
                                                  thumbnail,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: _primary,
                                                    size: 40,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.shopping_bag_outlined,
                                                  color: _primary,
                                                  size: 40,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$$price',
                                                style: const TextStyle(
                                                  color: _primaryDark,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '$rating',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
