import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // encryptedSharedPreferences puede colgarse en algunos Xiaomi al primer acceso.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
  );

  static const Duration _timeout = Duration(seconds: 2);

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token).timeout(_timeout);
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey).timeout(_timeout);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey).timeout(_timeout);
  }

  // User data
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final userJson = jsonEncode(userData);
    await _storage.write(key: _userKey, value: userJson).timeout(_timeout);
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey).timeout(_timeout);
      if (userJson != null) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey).timeout(_timeout);
  }

  // Clear all
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll().timeout(_timeout);
    } catch (_) {
      // ignore
    }
  }
}
