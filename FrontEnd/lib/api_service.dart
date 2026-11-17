import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  /// Base URL API.
  /// Secara otomatis:
  /// - Web / Windows Desktop: http://localhost:8080
  /// - Android Emulator: http://10.0.2.2:8080
  /// - HP Fisik: dapat disetel via `customBaseUrl`
  static String _customBaseUrl = '';

  static String get customBaseUrl => _customBaseUrl;

  static set customBaseUrl(String value) {
    _customBaseUrl = value.trim();
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl.endsWith('/')
          ? _customBaseUrl.substring(0, _customBaseUrl.length - 1)
          : _customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  /// Melakukan login menggunakan email dan kata sandi yang diverifikasi dari database MySQL.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Login berhasil!',
          'user': data is Map ? data['user'] : null,
        };
      } else {
        final message = data is Map && data['message'] != null
            ? data['message']
            : 'Email atau kata sandi tidak sesuai.';
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Gagal menghubungi server ($baseUrl). Pastikan backend Docker sudah berjalan.\nDetail: $e',
      };
    }
  }

  /// Mendaftarkan pengguna baru dan menyimpannya ke database MySQL.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/register');
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data is Map && data['message'] != null
              ? data['message']
              : 'Pendaftaran berhasil!',
          'user': data is Map ? data['user'] : null,
        };
      } else {
        final message = data is Map && data['message'] != null
            ? data['message']
            : 'Pendaftaran gagal.';
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Gagal menghubungi server ($baseUrl). Pastikan backend Docker sudah berjalan.\nDetail: $e',
      };
    }
  }

  /// Mengambil daftar produk dari database MySQL (opsional untuk ditampilkan setelah login).
  static Future<List<dynamic>> getProducts() async {
    final uri = Uri.parse('$baseUrl/products?limit=10');
    try {
      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['products'] is List) {
          return data['products'];
        }
      }
    } catch (_) {}
    return [];
  }
}
