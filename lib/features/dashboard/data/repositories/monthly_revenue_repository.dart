import 'package:sellari_umkm_frontend/features/dashboard/data/models/monthly_revenue_summary.dart';

abstract class MonthlyRevenueRepository {
  Future<MonthlyRevenueSummary> getSummary(int year, int month);
}
