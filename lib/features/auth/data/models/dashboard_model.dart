// lib/features/dashboard/data/models/dashboard_model.dart

int _parseInt(dynamic value) {
  final stringValue = value?.toString();
  if (stringValue == null || stringValue.isEmpty) return 0;
  return int.tryParse(stringValue) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();

  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) return 0.0;

  final normalizedValue = stringValue.replaceAll(',', '');
  return double.tryParse(normalizedValue) ?? 0.0;
}

class TodaySales {
  final double totalRevenue;
  final int totalTransactions;
  final String date;
  const TodaySales({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.date,
  });
  factory TodaySales.fromJson(Map<String, dynamic> j) => TodaySales(
        totalRevenue: _parseDouble(j['total_revenue']),
        totalTransactions: _parseInt(
          j['total_transactions'] ?? j['totalTransactions'],
        ),
        date: j['date']?.toString() ?? '',
      );
}

class BestProduct {
  final int id;
  final String productName;
  final int totalSold;
  const BestProduct({
    required this.id,
    required this.productName,
    required this.totalSold,
  });
  factory BestProduct.fromJson(Map<String, dynamic> j) => BestProduct(
        id: _parseInt(j['id']),
        productName: j['product_name']?.toString() ?? '',
        totalSold: _parseInt(j['total_sold']),
      );
}

class LowStockProduct {
  final int id, stock;
  final String productName;
  const LowStockProduct({
    required this.id,
    required this.productName,
    required this.stock,
  });
  factory LowStockProduct.fromJson(Map<String, dynamic> j) => LowStockProduct(
        id: _parseInt(j['id']),
        productName: j['product_name']?.toString() ?? '',
        stock: _parseInt(j['stock']),
      );
}

class RecentTransaction {
  final int id;
  final String productName;
  final double totalPrice;
  final String totalFormatted;
  final String transactionDate;
  final int quantity;

  const RecentTransaction({
    required this.id,
    required this.productName,
    required this.totalPrice,
    required this.totalFormatted,
    required this.transactionDate,
    required this.quantity,
  });

  factory RecentTransaction.fromJson(Map<String, dynamic> j) =>
      RecentTransaction(
        id: _parseInt(j['id']),
        productName:
            (j['product_name'] ?? j['product']?['product_name'])?.toString() ??
                '',
        totalPrice: _parseDouble(j['total_price']),
        totalFormatted: j['total_formatted']?.toString() ?? '',
        transactionDate: j['transaction_date']?.toString() ?? '',
        quantity: _parseInt(j['quantity']),
      );
}

class DashboardData {
  final TodaySales todaySales;
  final int totalTransactions;
  final int totalProducts;
  final int aiContentsGenerated;
  final BestProduct? bestSellingProduct;
  final List<LowStockProduct> lowStockProducts;
  final List<RecentTransaction> recentTransactions;
  final String? lastGeneratedCaption;

  const DashboardData({
    required this.todaySales,
    required this.totalTransactions,
    required this.totalProducts,
    required this.aiContentsGenerated,
    this.bestSellingProduct,
    this.lowStockProducts = const [],
    this.recentTransactions = const [],
    this.lastGeneratedCaption,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map<String, dynamic>)
        ? j['data'] as Map<String, dynamic>
        : j;

    Map<String, dynamic> getMap(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        if (map[key] is Map<String, dynamic>) {
          return map[key] as Map<String, dynamic>;
        }
      }
      return <String, dynamic>{};
    }

    List<dynamic> getList(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        if (map[key] is List) {
          return map[key] as List<dynamic>;
        }
      }
      return <dynamic>[];
    }

    final todaySalesJson = getMap(data, [
      'sales_today',
      'today_sales',
      'todaySales',
    ]);
    final bestSellingJson =
        data['best_selling_product'] ?? data['bestSellingProduct'];
    final lowStockList = getList(data, [
      'low_stock_products',
      'lowStockProducts',
    ]);
    final latestAiContent =
        data['latest_ai_content'] ?? data['latestAiContent'];
    final recentTransactionsList = getList(data, [
      'recent_transactions',
      'recentTransactions',
      'transactions',
    ]);
    final lastCaption = latestAiContent is Map<String, dynamic>
        ? latestAiContent['content']
        : (data['last_generated_caption'] ?? data['lastGeneratedCaption']);

    return DashboardData(
      todaySales: TodaySales.fromJson(todaySalesJson),
      totalTransactions: _parseInt(
        data['total_transactions'] ?? data['totalTransactions'],
      ),
      totalProducts: _parseInt(data['total_products'] ?? data['totalProducts']),
      aiContentsGenerated: _parseInt(
        data['ai_contents_generated'] ?? data['aiContentsGenerated'],
      ),
      bestSellingProduct: bestSellingJson is Map<String, dynamic>
          ? BestProduct.fromJson(bestSellingJson)
          : null,
      lowStockProducts: lowStockList
          .whereType<Map<String, dynamic>>()
          .map((p) => LowStockProduct.fromJson(p))
          .toList(),
      recentTransactions: (recentTransactionsList)
          .whereType<Map<String, dynamic>>()
          .map((item) => RecentTransaction.fromJson(item))
          .toList(),
      lastGeneratedCaption: lastCaption?.toString(),
    );
  }
}
