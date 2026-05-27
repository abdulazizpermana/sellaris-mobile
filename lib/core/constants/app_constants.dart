// lib/core/constants/app_constants.dart

class AppConstants {
  // ─── BASE URL ────────────────────────────────────────────────
  // Android Emulator  → gunakan 10.0.2.2
  // Device Fisik      → ganti dengan IP komputer kamu
  //                     Cek IP: jalankan 'ipconfig' di CMD Windows
  // Contoh: http://192.168.1.100:8000/api
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ─── Endpoints ───────────────────────────────────────────────
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String profile = '/profile';
  static const String products = '/products';
  static const String aiGenerate = '/ai/generate-content';
  static const String aiGenerateAll = '/ai/generate-all';
  static const String aiGenerateByFeature = '/ai/generate-by-feature';
  static const String aiHistory = '/ai/history';

  // ─── Transaction Endpoints ───────────────────────────────────
  static const String transactions = '/transactions';
  static const String transactionHistory = '/transactions/history'; // ← TAMBAH
  static const String dailyReport = '/transactions/daily-report';
  static const String monthlyReport = '/reports/monthly';

  static const String dashboard = '/dashboard';

  // ─── Storage Keys ────────────────────────────────────────────
  static const String tokenKey = 'auth_token';

  // ─── App Info ────────────────────────────────────────────────
  static const String appName = 'Sellaris';
}
