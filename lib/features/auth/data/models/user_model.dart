// lib/features/auth/data/models/user_model.dart

class BusinessProfile {
  final String businessName;
  final String category;
  final String? description;
  final String? phone;

  const BusinessProfile({
    required this.businessName,
    required this.category,
    this.description,
    this.phone,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> j) => BusinessProfile(
    businessName: j['business_name'] ?? '',
    category: j['category'] ?? '',
    description: j['description'],
    phone: j['phone'],
  );
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final BusinessProfile? businessProfile;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.businessProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'],
    name: j['name'],
    email: j['email'],
    businessProfile: j['business_profile'] != null
        ? BusinessProfile.fromJson(j['business_profile'])
        : null,
  );
}

class AuthResponse {
  final UserModel user;
  final String token;

  const AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> j) {
    final data = j['data'];
    return AuthResponse(
      user: UserModel.fromJson(data['user']),
      token: data['token'],
    );
  }
}
