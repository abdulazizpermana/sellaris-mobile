import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'core/constants/route_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/add_product_page.dart';
import 'features/auth/presentation/pages/product_page.dart';
import 'features/auth/presentation/pages/transaction_page.dart';
import 'features/ai/presentation/pages/ai_studio_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/product_bloc.dart';
import 'features/transaction/presentation/pages/transaction_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  await setupLocator();
  final themeCubit = await ThemeCubit.load();
  final localeCubit = await LocaleCubit.load();
  Intl.defaultLocale =
      localeCubit.state.languageCode == 'en' ? 'en_US' : 'id_ID';

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<LocaleCubit>.value(value: localeCubit),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            Intl.defaultLocale =
                locale.languageCode == 'en' ? 'en_US' : 'id_ID';

            return MaterialApp(
              title: 'Sellaris UMKM',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              locale: locale,
              routes: {
                AppRoutes.login: (_) => const LoginPage(),
                AppRoutes.register: (_) => const RegisterPage(),
                AppRoutes.home: (_) => const AppShell(),
                AppRoutes.product: (_) => const ProductPage(),
                AppRoutes.transaction: (_) => const TransactionPage(),
                AppRoutes.transactionHistory: (_) =>
                    const TransactionHistoryPage(),
                AppRoutes.aiStudio: (_) => const AiStudioPage(),
                AppRoutes.addProduct: (_) => BlocProvider(
                      create: (_) =>
                          sl<ProductBloc>()..add(ProductLoadRequested()),
                      child: const AddProductPage(),
                    ),
              },
              home: const AppEntry(),
            );
          },
        );
      },
    );
  }
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return const AppShell();
        }

        return const LoginPage();
      },
    );
  }
}
