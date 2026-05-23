// lib/features/auth/domain/repositories/auth_repository.dart

import '../../data/models/user_model.dart';

import 'dart:io';

abstract class AuthRepository {
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String businessName,
    required String category,
  });

  Future<AuthResponse> login({required String email, required String password});

  Future<void> logout();

  Future<UserModel> getProfile();

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
  });

  Future<bool> isLoggedIn();
}
