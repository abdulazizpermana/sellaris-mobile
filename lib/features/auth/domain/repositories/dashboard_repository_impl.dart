// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart

import 'package:sellari_umkm_frontend/features/auth/data/models/dashboard_model.dart';

import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _api;
  DashboardRepositoryImpl(this._api);

  @override
  Future<DashboardData> getDashboard() async {
    final res = await _api.get(AppConstants.dashboard);
    return DashboardData.fromJson(res.data);
  }
}
