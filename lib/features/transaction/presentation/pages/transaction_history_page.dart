import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sellari_umkm_frontend/core/di/service_locator.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';
import 'package:sellari_umkm_frontend/core/widgets/shared_widgets.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/transaction_model.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/transaction_bloc.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>(),
      child: const _TransactionHistoryView(),
    );
  }
}

class _TransactionHistoryView extends StatefulWidget {
  const _TransactionHistoryView();

  @override
  State<_TransactionHistoryView> createState() =>
      _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<_TransactionHistoryView> {
  final ScrollController _scrollController = ScrollController();
  final List<TransactionModel> _transactions = [];

  int _currentPage = 1;
  int _lastPage = 1;
  bool _isFetchingMore = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _didLoadInitial = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didLoadInitial) return;
      _didLoadInitial = true;
      context.read<TransactionBloc>().add(
            const TransactionHistoryRequested(page: 1),
          );
    });
  }

  void _disposeScrollController() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
  }

  bool get _hasMore => _currentPage < _lastPage;

  void _onScroll() {
    if (!_scrollController.hasClients || _isFetchingMore || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _isFetchingMore = true;
      context.read<TransactionBloc>().add(
            TransactionHistoryRequested(page: _currentPage + 1),
          );
    }
  }

  Future<void> _onRefresh() async {
    _isRefreshing = true;
    context.read<TransactionBloc>().add(
          const TransactionHistoryRequested(page: 1),
        );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _handleHistoryLoaded(TransactionHistoryLoaded state) {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _currentPage = state.currentPage;
      _lastPage = state.lastPage;
      _isFetchingMore = false;
      _isRefreshing = false;

      if (state.currentPage == 1) {
        _transactions
          ..clear()
          ..addAll(state.transactions);
      } else {
        final existingIds = _transactions.map((item) => item.id).toSet();
        final incoming = state.transactions
            .where((item) => !existingIds.contains(item.id))
            .toList();
        _transactions.addAll(incoming);
      }
    });
  }

  void _handleError(TransactionError state) {
    if (!mounted) return;
    setState(() {
      _isFetchingMore = false;
      _isRefreshing = false;
      _errorMessage = state.message;
    });
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return value;
    }
  }

  String _formatQuantity(int quantity) {
    final formatted = NumberFormat.decimalPattern('id_ID').format(quantity);
    return '$formatted item';
  }

  DateTime? _parseTransactionDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  bool _isSameOrAfter(DateTime value, DateTime target) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    final targetOnly = DateTime(target.year, target.month, target.day);
    return !dateOnly.isBefore(targetOnly);
  }

  bool _isSameOrBefore(DateTime value, DateTime target) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    final targetOnly = DateTime(target.year, target.month, target.day);
    return !dateOnly.isAfter(targetOnly);
  }

  List<TransactionModel> _filteredTransactions() {
    return _transactions.where((transaction) {
      final parsedDate = _parseTransactionDate(transaction.transactionDate);
      if (parsedDate == null) return _startDate == null && _endDate == null;
      if (_startDate != null && !_isSameOrAfter(parsedDate, _startDate!)) {
        return false;
      }
      if (_endDate != null && !_isSameOrBefore(parsedDate, _endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  String _filterLabel() {
    final formatter = DateFormat('d MMM yyyy', 'id_ID');
    if (_startDate != null && _endDate != null) {
      return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
    }
    if (_startDate != null) {
      return 'Dari ${formatter.format(_startDate!)}';
    }
    if (_endDate != null) {
      return 'Sampai ${formatter.format(_endDate!)}';
    }
    return 'Semua tanggal';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = picked);
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionHistoryLoaded) {
            _handleHistoryLoaded(state);
          } else if (state is TransactionError) {
            _handleError(state);
          }
        },
        builder: (context, state) {
          final isInitialLoading = state is TransactionLoading &&
              _transactions.isEmpty &&
              !_isRefreshing;

          if (isInitialLoading) {
            return const _TransactionHistoryShimmer();
          }

          if (_errorMessage != null && _transactions.isEmpty) {
            return ErrorView(
              message: _errorMessage!,
              onRetry: () {
                context.read<TransactionBloc>().add(
                      const TransactionHistoryRequested(page: 1),
                    );
              },
            );
          }

          final filteredTransactions = _filteredTransactions();
          final hasDateFilter = _startDate != null || _endDate != null;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DateFilterHeaderDelegate(
                    minExtentValue: 78,
                    maxExtentValue: 78,
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      alignment: Alignment.center,
                      child: _DateFilterBar(
                        filterLabel: _filterLabel(),
                        hasActiveFilter: hasDateFilter,
                        onPickStartDate: _pickStartDate,
                        onPickEndDate: _pickEndDate,
                        onClear: _clearDateFilter,
                      ),
                    ),
                  ),
                ),
                if (_transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyView(
                        title: 'Belum ada transaksi',
                        subtitle:
                            'Riwayat transaksi akan muncul setelah kamu mencatat penjualan.',
                        icon: Icons.receipt_long_rounded,
                        actionLabel: 'Muat Ulang',
                        onAction: () {
                          context.read<TransactionBloc>().add(
                                const TransactionHistoryRequested(page: 1),
                              );
                        },
                      ),
                    ),
                  )
                else if (filteredTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyView(
                        title: 'Tidak ada transaksi',
                        subtitle:
                            'Tidak ditemukan transaksi pada rentang tanggal yang dipilih.',
                        icon: Icons.date_range_rounded,
                        actionLabel: 'Reset Filter',
                        onAction: _clearDateFilter,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index < filteredTransactions.length) {
                          final transaction = filteredTransactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransactionHistoryCard(
                              transaction: transaction,
                              formattedDate: _formatDate(
                                transaction.transactionDate,
                              ),
                              formattedQuantity: _formatQuantity(
                                transaction.quantity,
                              ),
                            ),
                          );
                        }

                        if (_hasMore && index == filteredTransactions.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                          childCount:
                              filteredTransactions.length + (_hasMore ? 1 : 0)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget child;

  _DateFilterHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.child,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DateFilterHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentValue != minExtentValue ||
        oldDelegate.maxExtentValue != maxExtentValue ||
        oldDelegate.child != child;
  }
}

class _DateFilterBar extends StatelessWidget {
  final String filterLabel;
  final bool hasActiveFilter;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onClear;

  const _DateFilterBar({
    required this.filterLabel,
    required this.hasActiveFilter,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.filter_alt_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: 'Awal',
                    onTap: onPickStartDate,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: 'Akhir',
                    onTap: onPickEndDate,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      filterLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasActiveFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionHistoryCard extends StatelessWidget {
  final TransactionModel transaction;
  final String formattedDate;
  final String formattedQuantity;

  const _TransactionHistoryCard({
    required this.transaction,
    required this.formattedDate,
    required this.formattedQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final productName = transaction.product?.productName.isNotEmpty == true
        ? transaction.product!.productName
        : 'Produk tidak diketahui';
    final hasNotes =
        transaction.notes != null && transaction.notes!.trim().isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.primaryLight.withOpacity(0.55),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -18,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.success],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.successLight
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Riwayat penjualan',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.successLight,
                          Colors.white.withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.totalFormatted,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Jumlah',
                      value: formattedQuantity,
                      accent: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tanggal',
                      value: formattedDate,
                      accent: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (hasNotes) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.note_alt_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Catatan transaksi',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        transaction.notes!.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
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

class _TransactionHistoryShimmer extends StatelessWidget {
  const _TransactionHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 44, height: 44, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: double.infinity, height: 16, radius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 120, height: 12, radius: 8),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            ShimmerBox(width: double.infinity, height: 64, radius: 12),
            SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 14, radius: 8),
            SizedBox(height: 8),
            ShimmerBox(width: 180, height: 14, radius: 8),
          ],
        ),
      ),
    );
  }
}
