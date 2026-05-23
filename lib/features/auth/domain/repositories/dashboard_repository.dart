// lib/features/dashboard/domain/repositories/dashboard_repository.dart
import '../../data/models/dashboard_model.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboard();
}
