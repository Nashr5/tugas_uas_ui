import 'package:flutter/material.dart';

import 'api_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color _primary = Color(0xFF2962FF);
  static const Color _primaryDark = Color(0xFF0039CB);
  static const Color _bgSoft = Color(0xFFF8FAFC);
  static const Color _accentOrange = Color(0xFFFF6D00);

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.apps_rounded},
    {'name': 'Elektronik', 'icon': Icons.laptop_mac_rounded},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded},
    {'name': 'Gadget', 'icon': Icons.phone_android_rounded},
    {'name': 'Sepatu', 'icon': Icons.roller_skating_rounded},
    {'name': 'Kecantikan', 'icon': Icons.spa_rounded},
  ];

  // Database Produk Lokal untuk UI
  late List<Map<String, dynamic>> _allProducts;

  // Daftar Keranjang Belanja: Map { 'product': item, 'qty': int }
  final List<Map<String, dynamic>> _cart = [];

  // Daftar Notifikasi
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Diskon Spesial 70%',
      'body': 'Gunakan kode BELIKITA70 untuk potongan belanja pertamamu!',
      'time': '5 menit lalu',
      'unread': true,
    },
    {
      'title': 'Flash Sale Dimulai',
      'body': 'Produk kategori Elektronik diskon hingga 50% hari ini.',
      'time': '1 jam lalu',
      'unread': true,
    },
    {
      'title': 'Pesanan Berhasil Diproses',
      'body': 'Barangmu sedang dalam perjalanan menuju alamat pengiriman.',
      'time': 'Kemarin',
      'unread': false,
    },
  ];

  bool _voucherClaimed = false;

  @override
  void initState() {
    super.initState();
    _allProducts = [
      {
        'id': 1,
        'title': 'Wireless Headphones ANC Pro',
        'category': 'Elektronik',
        'price': 499000,
        'originalPrice': 799000,
        'discount': '37%',
        'rating': 4.9,
        'sold': '1.2k',
        'isFavorite': true,
        'color': const Color(0xFFE0E7FF),
        'icon': Icons.headphones_rounded,
        'description': 'Headphone nirkabel dengan Active Noise Cancellation canggih, daya tahan baterai hingga 40 jam, dan audio Hi-Res stereo bass mantap.',
      },
      {
        'id': 2,
        'title': 'Sneakers Casual Sporty Air-Walk',
        'category': 'Sepatu',
        'price': 289000,
        'originalPrice': 450000,
        'discount': '35%',
        'rating': 4.8,
        'sold': '850',
        'isFavorite': false,
        'color': const Color(0xFFFEF3C7),
        'icon': Icons.hiking_rounded,
        'description': 'Sepatu sneakers pria dan wanita dengan insole empuk memory foam, cocok untuk olahraga lari santai maupun aktivitas kasual harian.',
      },
      {
        'id': 3,
        'title': 'Smartwatch Ultra AMOLED Tracker',
        'category': 'Gadget',
        'price': 649000,
        'originalPrice': 999000,
        'discount': '35%',
        'rating': 4.9,
        'sold': '2.4k',
        'isFavorite': true,
        'color': const Color(0xFFDCFCE7),
        'icon': Icons.watch_rounded,
        'description': 'Smartwatch layar AMOLED jernih, tahan air 5ATM, fitur ECG & deteksi detak jantung 24/7, dan baterai tahan hingga 14 hari pemakaian.',
      },
      {
        'id': 4,
        'title': 'Kemeja Katun Casual Slim-Fit',
        'category': 'Fashion',
        'price': 139000,
        'originalPrice': 199000,
        'discount': '30%',
        'rating': 4.7,
        'sold': '540',
        'isFavorite': false,
        'color': const Color(0xFFFCE7F3),
        'icon': Icons.dry_cleaning_rounded,
        'description': 'Kemeja pria berbahan 100% katun oxford dingin, jahitan rapi kualitas distro premium, nyaman dipakai ke kantor maupun hangout.',
      },
      {
        'id': 5,
        'title': 'Serum Wajah Brightening Niacinamide',
        'category': 'Kecantikan',
        'price': 89000,
        'originalPrice': 130000,
        'discount': '31%',
        'rating': 4.9,
        'sold': '3.1k',
        'isFavorite': false,
        'color': const Color(0xFFF3E8FF),
        'icon': Icons.spa_rounded,
        'description': 'Serum pencerah kulit dengan kandungan 10% Niacinamide dan Zinc PCA untuk memudarkan noda hitam dan meratakan warna kulit wajah.',
      },
      {
        'id': 6,
        'title': 'Powerbank Fast Charging 20.000 mAh',
        'category': 'Gadget',
        'price': 199000,
        'originalPrice': 299000,
        'discount': '33%',
        'rating': 4.8,
        'sold': '1.8k',
        'isFavorite': false,
        'color': const Color(0xFFE0F2FE),
        'icon': Icons.battery_charging_full_rounded,
        'description': 'Powerbank kapasitas besar mendukung teknologi Quick Charge 3.0 dan Power Delivery 22.5W dengan dual input Type-C & Micro USB.',
      },
    ];

    // Isi awal keranjang (contoh)
    _cart.add({'product': _allProducts[0], 'qty': 1});
    _cart.add({'product': _allProducts[2], 'qty': 2});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter produk berdasarkan Search Query dan Kategori terpilih
  List<Map<String, dynamic>> get _filteredProducts {
    final selectedCategory =
        _categories[_selectedCategoryIndex]['name'] as String;
    return _allProducts.where((p) {
      final matchesCategory =
          selectedCategory == 'Semua' || p['category'] == selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          (p['title'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (p['category'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Hitung total item di keranjang
  int get _totalCartItems {
    return _cart.fold(0, (sum, item) => sum + (item['qty'] as int));
  }

  // Hitung total harga keranjang
  int get _totalCartPrice {
    return _cart.fold(0, (sum, item) {
      final product = item['product'] as Map<String, dynamic>;
      final qty = item['qty'] as int;
      return sum + ((product['price'] as int) * qty);
    });
  }

  // Daftar item Wishlist
  List<Map<String, dynamic>> get _wishlistItems {
    return _allProducts.where((p) => p['isFavorite'] == true).toList();
  }

  // Format Angka ke Rupiah
  String _rupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // Logika Tambah ke Keranjang
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere(
        (c) => c['product']['id'] == product['id'],
      );
      if (index >= 0) {
        _cart[index]['qty'] = (_cart[index]['qty'] as int) + 1;
      } else {
        _cart.add({'product': product, 'qty': 1});
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['title']} ditambahkan ke keranjang!'),
        backgroundColor: const Color(0xFF0D9488),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.amberAccent,
          onPressed: _openCartModal,
        ),
      ),
    );
  }

  // Logika Toggle Wishlist
  void _toggleWishlist(Map<String, dynamic> product) {
    setState(() {
      product['isFavorite'] = !(product['isFavorite'] as bool);
    });

    final isFav = product['isFavorite'] as bool;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? 'Ditambahkan ke Wishlist!' : 'Dihapus dari Wishlist.',
        ),
        backgroundColor: isFav ? const Color(0xFFE11D48) : Colors.grey[800],
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- MODAL BOTTOM SHEET VIEWS ---

  // 1. MODAL KERANJANG BELANJA LENGKAP
  void _openCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_rounded,
                            color: _primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Keranjang Belanja ($_totalCartItems)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Daftar Barang
                Expanded(
                  child: _cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Keranjangmu masih kosong',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Yuk cari barang impianmu di katalog!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _cart.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            final product =
                                item['product'] as Map<String, dynamic>;
                            final qty = item['qty'] as int;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bgSoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: product['color'] as Color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      product['icon'] as IconData,
                                      color: _primaryDark,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['title'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _rupiah(product['price'] as int),
                                          style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Kontrol Jumlah (+ / -)
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (qty > 1) {
                                              item['qty'] = qty - 1;
                                            } else {
                                              _cart.removeAt(index);
                                            }
                                          });
                                          setModalState(() {});
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          '$qty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: _primary,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            item['qty'] = qty + 1;
                                          });
                                          setModalState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Bagian Bawah Checkout
                if (_cart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pembayaran:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              _rupiah(_totalCartPrice),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(
                              Icons.payment_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Checkout Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _cart.clear());
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 28,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Pesanan Berhasil!'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Terima kasih sudah berbelanja di Belikita. Pesanan Anda akan segera diproses.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 2. MODAL WISHLIST LENGKAP
  void _openWishlistModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final wishlists = _wishlistItems;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Wishlist Saya (${wishlists.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: wishlists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada produk favorit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tekan icon hati pada produk yang kamu suka!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: wishlists.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final product = wishlists[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bgSoft,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: product['color'] as Color,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      product['icon'] as IconData,
                                      color: _primaryDark,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['title'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _rupiah(product['price'] as int),
                                          style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tombol Pindah ke Keranjang
                                  IconButton(
                                    tooltip: 'Tambah ke Keranjang',
                                    icon: const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: _primary,
                                    ),
                                    onPressed: () {
                                      _addToCart(product);
                                      setModalState(() {});
                                    },
                                  ),
                                  // Hapus dari Wishlist
                                  IconButton(
                                    tooltip: 'Hapus',
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        product['isFavorite'] = false;
                                      });
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. MODAL DETAIL PRODUK
  void _openProductDetail(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar / Preview Besar
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: product['color'] as Color,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Icon(
                          product['icon'] as IconData,
                          size: 100,
                          color: _primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Kategori & Diskon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product['category'] as String,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accentOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Diskon ${product['discount']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Judul Produk
                    Text(
                      product['title'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating & Terjual
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product['rating']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  Terjual ${product['sold']}+ item',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Harga
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _rupiah(product['price'] as int),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _rupiah(product['originalPrice'] as int),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Deskripsi Produk
                    const Text(
                      'Deskripsi Produk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol Aksi Bawah
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Tombol Wishlist
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: Icon(
                        (product['isFavorite'] as bool)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: (product['isFavorite'] as bool)
                            ? Colors.redAccent
                            : Colors.grey[600],
                      ),
                      onPressed: () {
                        _toggleWishlist(product);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Tambah ke Keranjang
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '+ Keranjang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _addToCart(product);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. MODAL NOTIFIKASI
  void _openNotificationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: _primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pemberitahuan & Promo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (notif['unread'] as bool)
                              ? const Color(0xFFDBEAFE)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_offer_rounded,
                          size: 18,
                          color: (notif['unread'] as bool)
                              ? _primary
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'] as String,
                              style: TextStyle(
                                fontWeight: (notif['unread'] as bool)
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notif['body'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['time'] as String,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. MODAL PROFIL & AKUN
  void _openAccountModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 36,
              backgroundColor: _primary,
              child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kelompok PPB Belikita',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'admin@belikita.com',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: _primary),
              title: const Text('Riwayat Transaksi'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Riwayat Transaksi...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Colors.grey),
              title: const Text('Pengaturan Aplikasi'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Keluar (Logout)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD WIDGET UTAMA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header (Brand, Greeting, Icons & Interactive Search)
            SliverToBoxAdapter(child: _buildHeader()),

            // 2. Hero Promotional Banner
            SliverToBoxAdapter(child: _buildHeroBanner()),

            // 3. 3 Kartu Arah Navigasi Utama (Katalog, Keranjang, Wishlist)
            SliverToBoxAdapter(child: _buildPrimaryActionCards()),

            // 4. Filter Kategori Produk
            SliverToBoxAdapter(child: _buildCategoryList()),

            // 5. Section Header Flash Sale
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                title: _searchQuery.isNotEmpty
                    ? 'Hasil Pencarian "$_searchQuery"'
                    : 'Rekomendasi Produk',
                actionText: _searchQuery.isNotEmpty ? 'Reset' : 'Semua',
                onActionTap: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedCategoryIndex = 0;
                  });
                },
              ),
            ),

            // 6. Grid Produk Aktif
            _filteredProducts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada produk yang cocok',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba gunakan kata kunci atau kategori lain',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.65,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildProductCard(_filteredProducts[index]),
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // WIDGET HEADER DENGAN SEARCH INPUT BERFUNGSI AKTIF
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Belikita',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Temukan barang impianmu hari ini',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Icon Notifikasi
                  _buildIconButton(
                    icon: Icons.notifications_none_rounded,
                    hasBadge: true,
                    onTap: _openNotificationModal,
                  ),
                  const SizedBox(width: 8),
                  // Icon Keranjang Belanja
                  _buildIconButton(
                    icon: Icons.shopping_cart_outlined,
                    hasBadge: _totalCartItems > 0,
                    badgeText: _totalCartItems > 0 ? '$_totalCartItems' : null,
                    onTap: _openCartModal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field Berfungsi Nyata
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari produk impianmu di Belikita...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[400],
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    bool hasBadge = false,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF334155)),
          ),
        ),
        if (hasBadge)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(badgeText != null ? 3 : 4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: badgeText != null
                  ? Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        height: 145,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryDark, _primary, Color(0xFF3B82F6)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.amberAccent,
                      size: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Promo Spesial Mahasiswa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diskon Hingga 70%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Gratis Ongkir ke Seluruh Indonesia 🚚',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (!_voucherClaimed) {
                    setState(() => _voucherClaimed = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Voucher Diskon 70% Berhasil Diklaim! 🎉',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voucher Anda sudah aktif!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _voucherClaimed ? '✓ Voucher Aktif' : 'Klaim Voucher',
                        style: TextStyle(
                          color: _voucherClaimed ? Colors.green : _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _voucherClaimed
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: _voucherClaimed ? Colors.green : _primary,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3 KARTU UTAMA: KATALOG PRODUK, KERANJANG, WISHLIST
  Widget _buildPrimaryActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigasi Utama',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // 1. Kartu Katalog Produk (Reset filter & fokus ke semua produk)
          InkWell(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = 0;
                _searchQuery = '';
                _searchController.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menampilkan Seluruh Katalog Produk'),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Katalog Produk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.stars_rounded,
                              color: Colors.amberAccent,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_allProducts.length} Produk aktif siap dibeli',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Baris Keranjang & Wishlist
          Row(
            children: [
              // Kartu Keranjang
              Expanded(
                child: _buildSecondaryCard(
                  title: 'Keranjang',
                  subtitle: '$_totalCartItems Item Disimpan',
                  badgeText: '$_totalCartItems Item',
                  icon: Icons.shopping_cart_checkout_rounded,
                  gradientColors: const [Color(0xFF0F766E), Color(0xFF0D9488)],
                  onTap: _openCartModal,
                ),
              ),
              const SizedBox(width: 12),
              // Kartu Wishlist
              Expanded(
                child: _buildSecondaryCard(
                  title: 'Wishlist',
                  subtitle: '${_wishlistItems.length} Favorit',
                  badgeText: '${_wishlistItems.length} Item',
                  icon: Icons.favorite_rounded,
                  gradientColors: const [Color(0xFFBE123C), Color(0xFFE11D48)],
                  onTap: _openWishlistModal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // LIST KATEGORI HORIZONTAL (FILTER BERFUNGSI)
  Widget _buildCategoryList() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: 'Kategori Populer'),
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // KARTU PRODUK DENGAN DETAIL, FAVORITE, DAN TAMBAH KE KERANJANG
  Widget _buildProductCard(Map<String, dynamic> product) {
    return InkWell(
      onTap: () => _openProductDetail(product),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar / Icon Preview
            Stack(
              children: [
                Container(
                  height: 115,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: product['color'] as Color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      product['icon'] as IconData,
                      size: 48,
                      color: _primaryDark,
                    ),
                  ),
                ),
                // Badge Diskon
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _accentOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product['discount'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Tombol Favorite (Wishlist Langsung Aktif)
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => _toggleWishlist(product),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (product['isFavorite'] as bool)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: (product['isFavorite'] as bool)
                            ? Colors.redAccent
                            : Colors.grey[400],
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Detail Produk
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product['rating']}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Terjual ${product['sold']}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _rupiah(product['price'] as int),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                          Text(
                            _rupiah(product['originalPrice'] as int),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      // Tombol Tambah ke Keranjang Langsung
                      InkWell(
                        onTap: () => _addToCart(product),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
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
  }

  // BOTTOM NAVIGATION BAR BERFUNGSI REAL-TIME
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            // Beranda
            setState(() {
              _selectedCategoryIndex = 0;
              _searchQuery = '';
              _searchController.clear();
            });
          } else if (index == 1) {
            // Katalog
            setState(() {
              _selectedCategoryIndex = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Menampilkan Seluruh Katalog Produk'),
                duration: Duration(milliseconds: 900),
              ),
            );
          } else if (index == 2) {
            // Wishlist
            _openWishlistModal();
          } else if (index == 3) {
            // Keranjang
            _openCartModal();
          } else if (index == 4) {
            // Akun
            _openAccountModal();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Katalog',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _wishlistItems.isNotEmpty,
              label: Text('${_wishlistItems.length}'),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _totalCartItems > 0,
              label: Text('$_totalCartItems'),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Keranjang',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
