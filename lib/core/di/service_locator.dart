// lib/core/di/service_locator.dart

import 'package:get_it/get_it.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/auth_repository_impl.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/dashboard_repository.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/dashboard_repository_impl.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/product_repository.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/product_repository_impl.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/transaction_repository.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/transaction_repository_impl.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/dashboard_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/product_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/transaction_bloc.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  // ─── Core ─────────────────────────────────────────────────
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // ─── Repositories ─────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );

  // ─── BLoCs ────────────────────────────────────────────────
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<ProductBloc>(() => ProductBloc(sl()));
  sl.registerFactory<TransactionBloc>(() => TransactionBloc(sl()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl()));
}
