// lib/features/transaction/domain/repositories/transaction_repository.dart
import '../../data/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<TransactionModel> createTransaction({
    required int productId,
    required int quantity,
    String? notes,
    String? date,
  });
  Future<DailyReport> getDailyReport(String date);
  Future<Map<String, dynamic>> getHistory({int page = 1});
}
