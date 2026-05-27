import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/core/network/api_client.dart';
import 'package:sellari_umkm_frontend/features/dashboard/data/models/monthly_revenue_summary.dart';
import 'package:sellari_umkm_frontend/features/dashboard/data/repositories/monthly_revenue_repository.dart';

abstract class MonthlyRevenueEvent extends Equatable {
  const MonthlyRevenueEvent();

  @override
  List<Object?> get props => [];
}

class MonthlyRevenueLoadRequested extends MonthlyRevenueEvent {
  final int year;
  final int month;

  const MonthlyRevenueLoadRequested({
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [year, month];
}

abstract class MonthlyRevenueState extends Equatable {
  const MonthlyRevenueState();

  @override
  List<Object?> get props => [];
}

class MonthlyRevenueInitial extends MonthlyRevenueState {}

class MonthlyRevenueLoading extends MonthlyRevenueState {}

class MonthlyRevenueLoaded extends MonthlyRevenueState {
  final MonthlyRevenueSummary summary;

  const MonthlyRevenueLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class MonthlyRevenueError extends MonthlyRevenueState {
  final String message;

  const MonthlyRevenueError(this.message);

  @override
  List<Object?> get props => [message];
}

class MonthlyRevenueBloc
    extends Bloc<MonthlyRevenueEvent, MonthlyRevenueState> {
  final MonthlyRevenueRepository _repository;

  MonthlyRevenueBloc(this._repository) : super(MonthlyRevenueInitial()) {
    on<MonthlyRevenueLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    MonthlyRevenueLoadRequested event,
    Emitter<MonthlyRevenueState> emit,
  ) async {
    emit(MonthlyRevenueLoading());

    try {
      final summary = await _repository.getSummary(event.year, event.month);
      emit(MonthlyRevenueLoaded(summary));
    } on ApiException catch (ex) {
      emit(MonthlyRevenueError(ex.message));
    } catch (ex, stack) {
      emit(
        MonthlyRevenueError(
          'Gagal memuat ringkasan pendapatan bulanan: ${ex.toString()}',
        ),
      );
      // ignore: avoid_print
      print('Monthly revenue load error: $ex\n$stack');
    }
  }
}
