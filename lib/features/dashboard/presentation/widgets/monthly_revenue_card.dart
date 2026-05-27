import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';
import 'package:sellari_umkm_frontend/features/dashboard/presentation/bloc/monthly_revenue_bloc.dart';

class MonthlyRevenueCard extends StatelessWidget {
  const MonthlyRevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyRevenueBloc, MonthlyRevenueState>(
      builder: (context, state) {
        if (state is MonthlyRevenueLoading || state is MonthlyRevenueInitial) {
          return _MonthlyRevenueContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _CardHeader(),
                SizedBox(height: 16),
                _LoadingBar(widthFactor: 0.55, height: 28),
                SizedBox(height: 12),
                _LoadingBar(widthFactor: 0.85, height: 14),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _LoadingMetric()),
                    SizedBox(width: 10),
                    Expanded(child: _LoadingMetric()),
                  ],
                ),
              ],
            ),
          );
        }

        if (state is MonthlyRevenueError) {
          return _MonthlyRevenueContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardHeader(),
                const SizedBox(height: 14),
                Text(
                  'Ringkasan pendapatan bulanan belum bisa dimuat.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          );
        }

        final loaded = state as MonthlyRevenueLoaded;
        final summary = loaded.summary;
        final growthText = summary.hasPrevData
            ? '${summary.isGrowthPositive ? '+' : ''}${summary.growthPercent.toStringAsFixed(1)}% vs bulan lalu'
            : 'Belum ada data pembanding bulan lalu';

        return _MonthlyRevenueContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(),
              const SizedBox(height: 14),
              Text(
                summary.revenueFormatted,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Periode ${summary.monthLabel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: summary.hasPrevData
                      ? (summary.isGrowthPositive
                          ? AppColors.successLight
                          : AppColors.errorLight)
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      summary.hasPrevData
                          ? (summary.isGrowthPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded)
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: summary.hasPrevData
                          ? (summary.isGrowthPositive
                              ? AppColors.success
                              : AppColors.error)
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        growthText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: summary.hasPrevData
                                  ? (summary.isGrowthPositive
                                      ? AppColors.success
                                      : AppColors.error)
                                  : AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Transaksi',
                      value: '${summary.totalTransactions}x',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Item Terjual',
                      value: '${summary.totalItemsSold} pcs',
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pendapatan Bulanan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Snapshot performa penjualan bulan ini',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRevenueContainer extends StatelessWidget {
  final Widget child;

  const _MonthlyRevenueContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingMetric extends StatelessWidget {
  const _LoadingMetric();

  @override
  Widget build(BuildContext context) {
    return const _LoadingBar(widthFactor: 1, height: 88);
  }
}

class _LoadingBar extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _LoadingBar({
    required this.widthFactor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
