// lib/features/transaction/presentation/pages/transaction_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/product_model.dart';
import 'package:sellari_umkm_frontend/features/auth/domain/repositories/product_repository.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/transaction_bloc.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});
  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final _qtyCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  List<ProductModel> _products = [];
  ProductModel? _selected;
  bool _loadingProducts = true;
  DateTime _date = DateTime.now();
  final _fmt = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final repo = sl<ProductRepository>();
      final list = await repo.getProducts();
      setState(() {
        _products = list;
        _loadingProducts = false;
      });
    } catch (_) {
      setState(() => _loadingProducts = false);
    }
  }

  double get _total {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    return (_selected?.price ?? 0) * qty;
  }

  void _submit(BuildContext ctx) {
    if (_selected == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk dulu'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Jumlah harus lebih dari 0'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }
    ctx.read<TransactionBloc>().add(
      TransactionCreateRequested(
        productId: _selected!.id,
        quantity: qty,
        notes: _notesCtrl.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Catat Penjualan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<TransactionBloc, TransactionState>(
          listener: (ctx, state) {
            if (state is TransactionSuccess) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    'Penjualan ${state.transaction.totalFormatted} berhasil dicatat! 💰',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
              setState(() {
                _selected = null;
                _qtyCtrl.text = '1';
                _notesCtrl.clear();
              });
              _loadProducts(); // refresh stok
            } else if (state is TransactionError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          builder: (ctx, state) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Pilih Produk ─────────────────────────
                Text('Produk', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                if (_loadingProducts)
                  const ShimmerBox(
                    width: double.infinity,
                    height: 56,
                    radius: 12,
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selected?.id,
                    hint: const Text('Pilih produk...'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    items: _products
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p.id,
                            child: Text('${p.productName} (Stok: ${p.stock})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selected = value == null
                          ? null
                          : _products.firstWhere(
                              (p) => p.id == value,
                              orElse: () => _products.isNotEmpty
                                  ? _products.first
                                  : throw StateError('No product found'),
                            );
                    }),
                  ),

                if (_selected != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Harga: ${_selected!.priceFormatted}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ─── Jumlah ───────────────────────────────
                Text(
                  'Jumlah Terjual',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final v = int.tryParse(_qtyCtrl.text) ?? 1;
                        if (v > 1) {
                          setState(() => _qtyCtrl.text = (v - 1).toString());
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: SField(
                        controller: _qtyCtrl,
                        label: '',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final v = int.tryParse(_qtyCtrl.text) ?? 0;
                        setState(() => _qtyCtrl.text = (v + 1).toString());
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppColors.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── Tanggal ──────────────────────────────
                Text(
                  'Tanggal Transaksi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Catatan ──────────────────────────────
                SField(
                  controller: _notesCtrl,
                  label: 'Catatan (opsional)',
                  hint: 'Contoh: Beli langsung, transfer BCA...',
                  prefixIcon: Icons.note_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // ─── Total Preview ────────────────────────
                if (_selected != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Penjualan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Rp ${_fmt.format(_total)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                LoadingButton(
                  isLoading: state is TransactionLoading,
                  label: '💰 Catat Penjualan',
                  onPressed: () => _submit(ctx),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
