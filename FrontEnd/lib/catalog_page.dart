
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const Color primary = Color(0xFF2962FF);
  static const Color primaryDark = Color(0xFF0039CB);

  final TextEditingController _searchController =
      TextEditingController();

  String selectedCategory = 'Semua';

  List<dynamic> products = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Elektronik',
    'Fashion',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mengambil produk dari API
  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getProducts(
        search: _searchController.text.trim(),
        category: selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // Form tambah dan edit produk
  Future<void> showProductForm({Map<String, dynamic>? product}) async {
    final isEdit = product != null;

    final titleController = TextEditingController(
      text: product?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: product?['description']?.toString() ?? '',
    );
    final categoryController = TextEditingController(
      text: product?['category']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: product?['stock']?.toString() ?? '',
    );
    final brandController = TextEditingController(
      text: product?['brand']?.toString() ?? '',
    );
    final thumbnailController = TextEditingController(
      text: product?['thumbnail']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

        await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false; // <-- Tambahkan variabel ini

        return StatefulBuilder(    // <-- Bungkus dengan StatefulBuilder
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _formField(titleController, 'Nama Produk', required: true),
                        _formField(descriptionController, 'Deskripsi'),
                        _formField(categoryController, 'Kategori'),
                        _formField(
                          priceController,
                          'Harga',
                          required: true,
                          number: true,
                        ),
                        _formField(
                          stockController,
                          'Stok',
                          number: true,
                        ),
                        _formField(brandController, 'Merek'),
                        _formField(thumbnailController, 'URL Gambar'),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          final data = <String, dynamic>{
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'category': categoryController.text.trim(),
                            'price': double.tryParse(priceController.text) ?? 0,
                            'stock': int.tryParse(stockController.text) ?? 0,
                            'brand': brandController.text.trim(),
                            'thumbnail': thumbnailController.text.trim(),
                          };

                          try {
                            if (isEdit) {
                              await ApiService.updateProduct(
                                int.parse(product['id'].toString()),
                                data,
                              );
                            } else {
                              await ApiService.addProduct(data);
                            }

                            Navigator.pop(dialogContext);
                            await loadProducts();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Produk berhasil diperbarui!'
                                      : 'Produk berhasil ditambahkan!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan produk: $e')),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    priceController.dispose();
    stockController.dispose();
    brandController.dispose();
    thumbnailController.dispose();
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return '$label wajib diisi';
          }
          if (number &&
              value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
      ),
    );
  }

  // Hapus produk
  Future<void> deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus produk ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteProduct(id);
      await loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  // Tampilan kartu produk
  Widget buildProductCard(Map<String, dynamic> product) {
    final imageUrl = product['thumbnail']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 85,
                      height: 85,
                      color: const Color(0xFFF0F2F5),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : Container(
                    width: 85,
                    height: 85,
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: primary,
                      size: 35,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title']?.toString() ?? 'Tanpa Nama',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product['category']?.toString() ?? 'Tanpa Kategori',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${product['price'] ?? 0}',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Stok: ${product['stock'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => showProductForm(product: product),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: primary,
                ),
              ),
              IconButton(
                tooltip: 'Hapus',
                onPressed: () => deleteProduct(
                  int.parse(product['id'].toString()),
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER BELIKITA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: primary,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BeliKita',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Temukan produk favoritmu',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ],
              ),
            ),

            // KONTEN CATALOG
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Berbelanja!',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202127),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Cari dan temukan produk yang kamu inginkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SEARCH BAR
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => loadProducts(),
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF50545E),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _searchController.clear();
                            loadProducts();
                          },
                          icon: const Icon(Icons.close),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F4F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // CATEGORY
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202127),
                      ),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected =
                              selectedCategory == category;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                              });
                              loadProducts();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary
                                    : const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF50545E),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // PRODUCT SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produk',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202127),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => showProductForm(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (errorMessage != null)
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gagal memuat produk',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: loadProducts,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    else if (products.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 35,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 55,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada produk',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Tambahkan produk pertamamu!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...products.map(
                        (item) => buildProductCard(
                          Map<String, dynamic>.from(item),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
