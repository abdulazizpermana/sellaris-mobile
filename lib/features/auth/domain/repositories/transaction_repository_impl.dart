// lib/features/transaction/data/repositories/transaction_repository_impl.dart

import 'package:sellari_umkm_frontend/features/auth/data/models/transaction_model.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final ApiClient _api;
  TransactionRepositoryImpl(this._api);

  @override
  Future<TransactionModel> createTransaction({
    required int productId,
    required int quantity,
    String? notes,
    String? date,
  }) async {
    final res = await _api.post(
      AppConstants.transactions,
      body: {
        'product_id': productId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (date != null && date.isNotEmpty) 'transaction_date': date,
      },
    );
    return TransactionModel.fromJson(res.data['data']);
  }

  @override
  Future<DailyReport> getDailyReport(String date) async {
    final res = await _api.get(AppConstants.dailyReport, query: {'date': date});
    return DailyReport.fromJson(res.data);
  }

  @override
  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final res = await _api.get(
      '/transactions/history',
      query: {'page': '$page'},
    );
    return res.data as Map<String, dynamic>;
  }
}
