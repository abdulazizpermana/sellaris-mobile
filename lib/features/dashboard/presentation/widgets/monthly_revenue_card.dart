import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';
import 'package:sellari_umkm_frontend/features/dashboard/data/models/monthly_revenue_summary.dart';
import 'package:sellari_umkm_frontend/features/dashboard/presentation/bloc/monthly_revenue_bloc.dart';

class MonthlyRevenueCard extends StatelessWidget {
  const MonthlyRevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyRevenueBloc, MonthlyRevenueState>(
      builder: (context, state) {
        if (state is MonthlyRevenueLoading || state is MonthlyRevenueInitial) {
          return const _MonthlyRevenueContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(),
                SizedBox(height: 18),
                _LoadingBar(widthFactor: 0.42, height: 12),
                SizedBox(height: 12),
                _LoadingBar(widthFactor: 0.62, height: 34),
                SizedBox(height: 10),
                _LoadingBar(widthFactor: 0.36, height: 12),
                SizedBox(height: 18),
                _LoadingHighlight(height: 52),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _LoadingHighlight(height: 92)),
                    SizedBox(width: 12),
                    Expanded(child: _LoadingHighlight(height: 92)),
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
                const SizedBox(height: 18),
                Text(
                  'Pendapatan bulanan belum bisa dimuat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coba refresh halaman untuk memuat ulang ringkasan pendapatan.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final loaded = state as MonthlyRevenueLoaded;
        final summary = loaded.summary;

        return _MonthlyRevenueContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(),
              const SizedBox(height: 18),
              Text(
                summary.revenueFormatted,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Periode ${summary.monthLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 16),
              _GrowthBanner(summary: summary),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Transaksi',
                      value: '${summary.totalTransactions}x',
                      icon: Icons.receipt_long_outlined,
                      accentColor: AppColors.primary,
                      softColor: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Item Terjual',
                      value: '${summary.totalItemsSold} pcs',
                      icon: Icons.shopping_bag_outlined,
                      accentColor: AppColors.success,
                      softColor: AppColors.successLight,
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
          width: 44,
          height: 44,
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
                'Ringkasan performa penjualan bulan ini',
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

class _GrowthBanner extends StatelessWidget {
  final MonthlyRevenueSummary summary;

  const _GrowthBanner({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPrevData = summary.hasPrevData;
    final bool isPositive = summary.isGrowthPositive;

    final Color backgroundColor = !hasPrevData
        ? AppColors.warningLight
        : isPositive
            ? AppColors.successLight
            : AppColors.errorLight;

    final Color foregroundColor = !hasPrevData
        ? AppColors.warning
        : isPositive
            ? AppColors.success
            : AppColors.error;

    final IconData icon = !hasPrevData
        ? Icons.schedule_rounded
        : isPositive
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    final String text = !hasPrevData
        ? 'Belum ada data pembanding bulan lalu'
        : '${isPositive ? '+' : ''}${summary.growthPercent.toStringAsFixed(1)}% dibanding bulan lalu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: foregroundColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color softColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingHighlight extends StatelessWidget {
  final double height;

  const _LoadingHighlight({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(16),
      ),
    );
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
