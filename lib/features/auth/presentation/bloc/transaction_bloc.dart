// lib/features/transaction/presentation/bloc/transaction_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class TransactionCreateRequested extends TransactionEvent {
  final int productId, quantity;
  final String? notes, date;
  const TransactionCreateRequested({
    required this.productId,
    required this.quantity,
    this.notes,
    this.date,
  });
}

class TransactionReportRequested extends TransactionEvent {
  final String date;
  const TransactionReportRequested(this.date);
  @override
  List<Object?> get props => [date];
}

// States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionSuccess extends TransactionState {
  final TransactionModel transaction;
  const TransactionSuccess(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class TransactionReportLoaded extends TransactionState {
  final DailyReport report;
  const TransactionReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _repo;
  TransactionBloc(this._repo) : super(TransactionInitial()) {
    on<TransactionCreateRequested>(_onCreate);
    on<TransactionReportRequested>(_onReport);
  }

  Future<void> _onCreate(
    TransactionCreateRequested e,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final t = await _repo.createTransaction(
        productId: e.productId,
        quantity: e.quantity,
        notes: e.notes,
        date: e.date,
      );
      emit(TransactionSuccess(t));
    } on ApiException catch (ex) {
      emit(TransactionError(ex.message));
    } catch (_) {
      emit(const TransactionError('Transaksi gagal dicatat'));
    }
  }

  Future<void> _onReport(
    TransactionReportRequested e,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final report = await _repo.getDailyReport(e.date);
      emit(TransactionReportLoaded(report));
    } on ApiException catch (ex) {
      emit(TransactionError(ex.message));
    } catch (_) {
      emit(const TransactionError('Gagal memuat laporan'));
    }
  }
}
