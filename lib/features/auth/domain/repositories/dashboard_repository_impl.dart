// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart

import 'package:sellari_umkm_frontend/features/auth/data/models/dashboard_model.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/transaction_model.dart';

import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _api;
  DashboardRepositoryImpl(this._api);

  @override
  Future<DashboardData> getDashboard() async {
    final dashboardRes = await _api.get(AppConstants.dashboard);
    final dashboardData = DashboardData.fromJson(dashboardRes.data);

    if (dashboardData.recentTransactions.isNotEmpty) {
      return dashboardData;
    }

    try {
      final historyRes = await _api.get(
        '/transactions/history',
        query: {'page': '1'},
      );

      final historyRoot = historyRes.data;
      final historyItems =
          historyRoot is Map<String, dynamic> ? historyRoot['data'] : null;

      final recentTransactions =
          (historyItems is List ? historyItems : const [])
              .whereType<Map<String, dynamic>>()
              .map(TransactionModel.fromJson)
              .take(3)
              .map(
                (item) => RecentTransaction(
                  id: item.id,
                  productName: item.product?.productName ?? 'Produk',
                  totalPrice: item.totalPrice,
                  totalFormatted: item.totalFormatted,
                  transactionDate: item.transactionDate,
                  quantity: item.quantity,
                ),
              )
              .toList();

      return DashboardData(
        todaySales: dashboardData.todaySales,
        totalTransactions: dashboardData.totalTransactions,
        totalProducts: dashboardData.totalProducts,
        aiContentsGenerated: dashboardData.aiContentsGenerated,
        bestSellingProduct: dashboardData.bestSellingProduct,
        lowStockProducts: dashboardData.lowStockProducts,
        recentTransactions: recentTransactions,
        lastGeneratedCaption: dashboardData.lastGeneratedCaption,
      );
    } catch (_) {
      return dashboardData;
    }
  }
}
