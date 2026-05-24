// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../ai/presentation/pages/ai_studio_page.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../data/models/dashboard_model.dart';
import '../../../dashboard/presentation/widgets/sellaris_score_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(DashboardLoadRequested()),
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
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (ctx, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ctx.read<DashboardBloc>().add(DashboardLoadRequested()),
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
                      onPressed: () => ctx.read<DashboardBloc>().add(
                            DashboardLoadRequested(),
                          ),
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
                        const SizedBox(height: 12),
                        const ShimmerBox(
                          width: double.infinity,
                          height: 80,
                          radius: 16,
                        ),
                        const SizedBox(height: 12),
                        const ShimmerBox(
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
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Penjualan Hari Ini',
                                value: currency.format(
                                  state.data.todaySales.totalRevenue,
                                ),
                                icon: Icons.payments_outlined,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Transaksi',
                                value: '${state.data.totalTransactions}x',
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Total Produk',
                                value: '${state.data.totalProducts}',
                                icon: Icons.inventory_2_outlined,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Konten AI Dibuat',
                                value: '${state.data.aiContentsGenerated}x',
                                icon: Icons.auto_awesome_rounded,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
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
                        _DashboardActionRow(),
                        const SizedBox(height: 16),
                        const SectionHeader(title: '🏆 Produk Terlaris'),
                        const SizedBox(height: 10),
                        _BestSellerCard(product: state.data.bestSellingProduct),
                        const SizedBox(height: 16),
                        if (state.data.lowStockProducts.isNotEmpty) ...[
                          const SectionHeader(title: '⚠️ Stok Menipis'),
                          const SizedBox(height: 10),
                          ...state.data.lowStockProducts.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LowStockItem(product: p),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (state.data.lastGeneratedCaption != null) ...[
                          const SectionHeader(title: '✨ Caption Terakhir'),
                          const SizedBox(height: 10),
                          _LastCaptionCard(
                            caption: state.data.lastGeneratedCaption!,
                          ),
                          const SizedBox(height: 16),
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

class _DashboardActionRow extends StatelessWidget {
  const _DashboardActionRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Navigasi Cepat'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DashboardActionCard(
              title: 'Produk Saya',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, AppRoutes.product),
            ),
            _DashboardActionCard(
              title: 'Catat Transaksi',
              icon: Icons.receipt_long_outlined,
              color: AppColors.success,
              onTap: () => Navigator.pushNamed(context, AppRoutes.transaction),
            ),
            _DashboardActionCard(
              title: 'Riwayat Transaksi',
              icon: Icons.history_rounded,
              color: AppColors.warning,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.transactionHistory),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DashboardActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(18),
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
                  product!.productName,
                  style: Theme.of(context).textTheme.titleMedium,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok tersisa ${product.stock}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Segera restock',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konten AI Terakhir',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(caption, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
