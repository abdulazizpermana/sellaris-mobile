// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../ai/presentation/pages/ai_studio_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../dashboard/presentation/bloc/monthly_revenue_bloc.dart';
import '../../../dashboard/presentation/widgets/monthly_revenue_card.dart';
import '../../../dashboard/presentation/widgets/sellaris_score_card.dart';
import '../../../transaction/presentation/pages/transaction_history_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../../data/models/dashboard_model.dart';
import 'transaction_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<DashboardBloc>()..add(DashboardLoadRequested()),
        ),
        BlocProvider(
          create: (_) => sl<MonthlyRevenueBloc>()
            ..add(
              MonthlyRevenueLoadRequested(
                year: now.year,
                month: now.month,
              ),
            ),
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state is AuthAuthenticated)
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    final currency = NumberFormat('Rp #,###', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          label: const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Text(
              'Catat Penjualan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionPage()),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (ctx, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              final now = DateTime.now();
              ctx.read<DashboardBloc>().add(DashboardLoadRequested());
              ctx.read<MonthlyRevenueBloc>().add(
                    MonthlyRevenueLoadRequested(
                      year: now.year,
                      month: now.month,
                    ),
                  );
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: true,
                  titleSpacing: 20,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Halo,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.name.split(' ').first ?? 'Penjual',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  surfaceTintColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sellaris AI Studio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Konten AI untuk produk lebih cepat.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AiStudioPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Generate Konten Sekarang'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final now = DateTime.now();
                        ctx.read<DashboardBloc>().add(DashboardLoadRequested());
                        ctx.read<MonthlyRevenueBloc>().add(
                              MonthlyRevenueLoadRequested(
                                year: now.year,
                                month: now.month,
                              ),
                            );
                      },
                    ),
                  ],
                ),
                if (state is DashboardLoading) ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: const [
                            Expanded(
                              child: ShimmerBox(
                                width: double.infinity,
                                height: 100,
                                radius: 16,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ShimmerBox(
                                width: double.infinity,
                                height: 100,
                                radius: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ShimmerBox(
                          width: double.infinity,
                          height: 80,
                          radius: 16,
                        ),
                        SizedBox(height: 12),
                        ShimmerBox(
                          width: double.infinity,
                          height: 120,
                          radius: 16,
                        ),
                      ]),
                    ),
                  ),
                ] else if (state is DashboardError) ...[
                  SliverFillRemaining(
                    child: ErrorView(
                      message: state.message,
                      onRetry: () => ctx.read<DashboardBloc>().add(
                            DashboardLoadRequested(),
                          ),
                    ),
                  ),
                ] else if (state is DashboardLoaded) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _DashboardInfoSection(
                          currency: currency,
                          totalRevenue: state.data.todaySales.totalRevenue,
                          totalTransactions: state.data.totalTransactions,
                          totalProducts: state.data.totalProducts,
                          aiContentsGenerated: state.data.aiContentsGenerated,
                        ),
                        const SizedBox(height: 18),
                        const MonthlyRevenueCard(),
                        const SizedBox(height: 18),
                        SellarisScoreCard(
                          score: 82,
                          onDetailTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Fitur segera hadir! 🚀'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _RecentTransactionsSection(
                          transactions:
                              state.data.recentTransactions.take(3).toList(),
                        ),
                        const SizedBox(height: 18),
                        const SectionHeader(title: 'Produk Terlaris'),
                        const SizedBox(height: 10),
                        _BestSellerCard(product: state.data.bestSellingProduct),
                        if (state.data.lowStockProducts.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const SectionHeader(title: 'Stok Menipis'),
                          const SizedBox(height: 10),
                          ...state.data.lowStockProducts.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LowStockItem(product: p),
                            ),
                          ),
                        ],
                        if (state.data.lastGeneratedCaption != null) ...[
                          const SizedBox(height: 18),
                          _LastCaptionCard(
                            caption: state.data.lastGeneratedCaption!,
                          ),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardInfoSection extends StatelessWidget {
  final NumberFormat currency;
  final num totalRevenue;
  final int totalTransactions;
  final int totalProducts;
  final int aiContentsGenerated;

  const _DashboardInfoSection({
    required this.currency,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalProducts,
    required this.aiContentsGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Ringkasan Hari Ini'),
        const SizedBox(height: 8),
        Text(
          'Bagian ini hanya untuk melihat performa usaha secara cepat.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashboardInfoCard(
                title: 'Penjualan',
                value: currency.format(totalRevenue),
                subtitle: 'Hari ini',
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardInfoCard(
                title: 'Transaksi',
                value: '${totalTransactions}x',
                subtitle: 'Total masuk',
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DashboardInfoCard(
                title: 'Total Produk',
                value: '$totalProducts',
                subtitle: 'Produk aktif',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardInfoCard(
                title: 'Konten AI',
                value: '${aiContentsGenerated}x',
                subtitle: 'Sudah dibuat',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  final List<RecentTransaction> transactions;

  const _RecentTransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionHeader(title: 'Transaksi Terbaru'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryPage(),
                  ),
                );
              },
              child: const Text('Lihat Semua →'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Belum ada transaksi hari ini',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...transactions.map(
            (transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecentTransactionItem(transaction: transaction),
            ),
          ),
      ],
    );
  }
}

class RecentTransactionItem extends StatelessWidget {
  final RecentTransaction transaction;

  const RecentTransactionItem({super.key, required this.transaction});

  String _formatDateLabel(String value) {
    try {
      final date = DateTime.parse(value);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = '${_formatDateLabel(transaction.transactionDate)} • '
        '${transaction.quantity} item';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.totalFormatted.isNotEmpty
                    ? transaction.totalFormatted
                    : NumberFormat('Rp #,###', 'id_ID')
                        .format(transaction.totalPrice),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'x${transaction.quantity}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BestSellerCard extends StatelessWidget {
  final BestProduct? product;
  const _BestSellerCard({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Data produk terbaik belum tersedia.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produk Terlaris',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  product!.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product!.totalSold} terjual',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final LowStockProduct product;
  const _LowStockItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok tersisa ${product.stock}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Segera restock',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastCaptionCard extends StatelessWidget {
  final String caption;
  const _LastCaptionCard({required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konten AI Terakhir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informasi ini hanya untuk dilihat sebagai referensi caption terakhir yang dibuat.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              caption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
