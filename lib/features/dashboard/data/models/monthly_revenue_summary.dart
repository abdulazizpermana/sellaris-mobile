import 'package:intl/intl.dart';

class MonthlyRevenueSummary {
  final int year;
  final int month;
  final double totalRevenue;
  final double prevMonthRevenue;
  final int totalTransactions;
  final int totalItemsSold;

  const MonthlyRevenueSummary({
    required this.year,
    required this.month,
    required this.totalRevenue,
    required this.prevMonthRevenue,
    required this.totalTransactions,
    required this.totalItemsSold,
  });

  String get revenueFormatted =>
      NumberFormat('Rp #,###', 'id_ID').format(totalRevenue);

  String get monthLabel =>
      DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));

  double get growthPercent {
    if (prevMonthRevenue == 0) return 0;
    return ((totalRevenue - prevMonthRevenue) / prevMonthRevenue) * 100;
  }

  bool get isGrowthPositive => growthPercent >= 0;

  bool get hasPrevData => prevMonthRevenue > 0;
}
