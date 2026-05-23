// lib/core/storage/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) async =>
      await _storage.write(key: AppConstants.tokenKey, value: token);

  Future<String?> getToken() async =>
      await _storage.read(key: AppConstants.tokenKey);

  Future<void> deleteToken() async =>
      await _storage.delete(key: AppConstants.tokenKey);

  Future<bool> hasToken() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async => await _storage.deleteAll();
}
