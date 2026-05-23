// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/network/api_client.dart';

// ─── Events ───────────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email, password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name, email, password, businessName, category;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.businessName,
    required this.category,
  });
  @override
  List<Object?> get props => [name, email, businessName, category];
}

class AuthLogoutRequested extends AuthEvent {}

// ─── States ───────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final loggedIn = await _repo.isLoggedIn();
    if (!loggedIn) return emit(AuthUnauthenticated());
    try {
      final user = await _repo.getProfile();
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await _repo.login(email: e.email, password: e.password);
      emit(AuthAuthenticated(res.user));
    } on ValidationException catch (ex) {
      emit(AuthError(ex.message));
    } on NetworkException catch (ex) {
      emit(AuthError(ex.message));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Login gagal. Periksa email & password.'));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final res = await _repo.register(
        name: e.name,
        email: e.email,
        password: e.password,
        businessName: e.businessName,
        category: e.category,
      );
      emit(AuthAuthenticated(res.user));
    } on ValidationException catch (ex) {
      emit(AuthError(ex.message));
    } on NetworkException catch (ex) {
      emit(AuthError(ex.message));
    } on ApiException catch (ex) {
      emit(AuthError(ex.message));
    } catch (_) {
      emit(const AuthError('Registrasi gagal. Coba lagi.'));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repo.logout();
    emit(AuthUnauthenticated());
  }
}
