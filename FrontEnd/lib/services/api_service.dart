import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Alamat backend Belikita
   static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8090';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 adalah IP host laptop untuk Emulator Android
      return 'http://10.0.2.2:8090';
    } else {
      // Untuk Windows desktop atau platform lainnya
      return 'http://localhost:8090';
    }
  }

  // Mengambil daftar produk
  static Future<List<dynamic>> getProducts({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{};

    if (search != null && search.isNotEmpty) {
      query['q'] = search;
    }

    if (category != null && category.isNotEmpty && category != 'Semua') {
      query['category'] = category;
    }

    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] as List<dynamic>;
    }

    throw Exception('Gagal mengambil produk: ${response.statusCode}');
  }

  // Menambahkan produk
  static Future<void> addProduct(Map<String, dynamic> product) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/products'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(product),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('Gagal menambahkan produk: ${response.body}');
    }
  }

  // Mengedit produk
  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> product,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengedit produk: ${response.body}');
    }
  }

  // Menghapus produk
  static Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus produk: ${response.body}');
    }
  }

  // Mengambil daftar kategori
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/category-list'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Gagal mengambil kategori');
  }
}
