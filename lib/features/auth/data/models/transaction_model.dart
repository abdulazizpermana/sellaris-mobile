// lib/features/transaction/data/models/transaction_model.dart

class TransactionProduct {
  final int id;
  final String productName;
  final double price;
  const TransactionProduct({
    required this.id,
    required this.productName,
    required this.price,
  });

  factory TransactionProduct.fromJson(Map<String, dynamic> j) =>
      TransactionProduct(
        id: j['id'],
        productName: j['product_name'],
        price: double.tryParse(j['price'].toString()) ?? 0,
      );
}

class TransactionModel {
  final int id, quantity;
  final double totalPrice;
  final String totalFormatted, transactionDate;
  final String? notes;
  final TransactionProduct? product;

  const TransactionModel({
    required this.id,
    required this.quantity,
    required this.totalPrice,
    required this.totalFormatted,
    required this.transactionDate,
    this.notes,
    this.product,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id: j['id'],
    quantity: j['quantity'],
    totalPrice: double.tryParse(j['total_price'].toString()) ?? 0,
    totalFormatted: j['total_formatted'] ?? '',
    transactionDate: j['transaction_date'] ?? '',
    notes: j['notes'],
    product: j['product'] != null
        ? TransactionProduct.fromJson(j['product'])
        : null,
  );
}

class DailyReport {
  final String date;
  final int totalTransactions, totalItemsSold;
  final double totalRevenue;
  final List<TransactionModel> transactions;

  const DailyReport({
    required this.date,
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.totalRevenue,
    required this.transactions,
  });

  factory DailyReport.fromJson(Map<String, dynamic> j) {
    final data = j['data'];
    return DailyReport(
      date: data['date'] ?? '',
      totalTransactions: data['total_transactions'] ?? 0,
      totalItemsSold: data['total_items_sold'] ?? 0,
      totalRevenue: double.tryParse(data['total_revenue'].toString()) ?? 0,
      transactions: (data['transactions'] as List? ?? [])
          .map((t) => TransactionModel.fromJson(t))
          .toList(),
    );
  }
}
