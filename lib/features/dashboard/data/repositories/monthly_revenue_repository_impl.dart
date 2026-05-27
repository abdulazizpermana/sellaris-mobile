import 'package:sellari_umkm_frontend/core/constants/app_constants.dart';
import 'package:sellari_umkm_frontend/core/network/api_client.dart';
import 'package:sellari_umkm_frontend/features/dashboard/data/models/monthly_revenue_summary.dart';
import 'package:sellari_umkm_frontend/features/dashboard/data/repositories/monthly_revenue_repository.dart';

class MonthlyRevenueRepositoryImpl implements MonthlyRevenueRepository {
  final ApiClient _apiClient;

  MonthlyRevenueRepositoryImpl(this._apiClient);

  @override
  Future<MonthlyRevenueSummary> getSummary(int year, int month) async {
    final previousPeriod = _getPreviousPeriod(year, month);

    final currentResponse = await _apiClient.get(
      AppConstants.monthlyReport,
      query: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );

    final previousResponse = await _apiClient.get(
      AppConstants.monthlyReport,
      query: {
        'year': previousPeriod.year.toString(),
        'month': previousPeriod.month.toString(),
      },
    );

    final currentData = _extractData(currentResponse.data);
    final previousData = _extractData(previousResponse.data);

    return MonthlyRevenueSummary(
      year: _toInt(currentData['year']) ?? year,
      month: _toInt(currentData['month']) ?? month,
      totalRevenue: _toDouble(currentData['total_revenue']),
      prevMonthRevenue: _toDouble(previousData['total_revenue']),
      totalTransactions: _toInt(currentData['total_transactions']) ?? 0,
      totalItemsSold: _toInt(currentData['total_items_sold']) ?? 0,
    );
  }

  ({int year, int month}) _getPreviousPeriod(int year, int month) {
    if (month == 1) {
      return (year: year - 1, month: 12);
    }

    return (year: year, month: month - 1);
  }

  Map<String, dynamic> _extractData(dynamic root) {
    if (root is Map<String, dynamic>) {
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }

    return {};
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
