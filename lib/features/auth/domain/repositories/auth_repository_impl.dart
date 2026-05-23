// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'dart:io';

import 'package:sellari_umkm_frontend/features/auth/data/models/user_model.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepositoryImpl(this._api, this._storage);

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required String category,
  }) async {
    final res = await _api.post(
      AppConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'business_name': businessName,
        'category': category,
      },
      auth: false,
    );
    final authRes = AuthResponse.fromJson(res.data);
    await _storage.saveToken(authRes.token);
    return authRes;
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post(
      AppConstants.login,
      body: {'email': email, 'password': password},
      auth: false,
    );
    final authRes = AuthResponse.fromJson(res.data);
    await _storage.saveToken(authRes.token);
    return authRes;
  }

  @override
  Future<void> logout() async {
    try {
      await _api.post(AppConstants.logout);
    } catch (_) {}
    await _storage.clearAll();
  }

  @override
  Future<UserModel> getProfile() async {
    final res = await _api.get(AppConstants.profile);
    return UserModel.fromJson(res.data['data']);
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? businessName,
    String? businessCategory,
    String? businessDescription,
    bool? darkMode,
    String? language,
    bool? notificationEnabled,
    String? aiTone,
    String? defaultTargetMarket,
    String? defaultPlatform,
    File? profilePhoto,
  }) async {
    final fields = <String, String>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (businessName != null && businessName.isNotEmpty)
        'business_name': businessName,
      if (businessCategory != null && businessCategory.isNotEmpty)
        'business_category': businessCategory,
      if (businessDescription != null)
        'business_description': businessDescription,
      if (darkMode != null) 'dark_mode': darkMode.toString(),
      if (language != null && language.isNotEmpty) 'language': language,
      if (notificationEnabled != null)
        'notification_enabled': notificationEnabled.toString(),
      if (aiTone != null && aiTone.isNotEmpty) 'ai_tone': aiTone,
      if (defaultTargetMarket != null && defaultTargetMarket.isNotEmpty)
        'default_target_market': defaultTargetMarket,
      if (defaultPlatform != null && defaultPlatform.isNotEmpty)
        'default_platform': defaultPlatform,
    };

    final res = await _api.putMultipart(
      AppConstants.profile,
      fields: fields,
      imageFile: profilePhoto,
      imageField: 'profile_photo',
    );

    return UserModel.fromJson(res.data['data']);
  }

  @override
  Future<bool> isLoggedIn() => _storage.hasToken();
}
