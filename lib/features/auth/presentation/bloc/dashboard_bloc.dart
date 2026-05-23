// lib/features/dashboard/presentation/bloc/dashboard_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/dashboard_model.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/network/api_client.dart';

abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  const DashboardLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repo;
  DashboardBloc(this._repo) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    DashboardLoadRequested e,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _repo.getDashboard();
      emit(DashboardLoaded(data));
    } on ApiException catch (ex) {
      emit(DashboardError(ex.message));
    } catch (ex, stack) {
      emit(DashboardError('Gagal memuat dashboard: ${ex.toString()}'));
      // ignore: avoid_print
      print('Dashboard load error: $ex\n$stack');
    }
  }
}
