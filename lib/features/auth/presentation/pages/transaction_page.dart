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
    _qtyCtrl.addListener(_handleQuantityChanged);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final repo = sl<ProductRepository>();
      final list = await repo.getProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  int get _selectedStock => _selected?.stock ?? 0;

  bool get _isOutOfStock => _selected != null && _selectedStock <= 0;

  bool get _isLowStock =>
      _selected != null && _selectedStock > 0 && _selectedStock <= 5;

  double get _total {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    return (_selected?.price ?? 0) * qty;
  }

  void _setQuantity(int value) {
    final normalizedValue = value < 1 ? 1 : value;
    final maxStock = _selectedStock;

    if (_selected != null && maxStock > 0 && normalizedValue > maxStock) {
      _qtyCtrl.text = maxStock.toString();
      return;
    }

    _qtyCtrl.text = normalizedValue.toString();
  }

  void _showWarningSnackBar(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
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
      _showWarningSnackBar(ctx, 'Jumlah harus lebih dari 0');
      return;
    }

    if (_isOutOfStock) {
      _showWarningSnackBar(
        ctx,
        'Stok produk sudah habis. Transaksi tidak bisa ditambahkan.',
      );
      return;
    }

    if (qty > _selectedStock) {
      _showWarningSnackBar(
        ctx,
        'Jumlah melebihi stok tersedia. Maksimal $_selectedStock item.',
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

  void _handleQuantityChanged() {
    final parsed = int.tryParse(_qtyCtrl.text);
    if (parsed == null) {
      return;
    }

    if (_selected != null && _selectedStock > 0 && parsed > _selectedStock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() => _setQuantity(_selectedStock));
        _showWarningSnackBar(
          context,
          'Jumlah maksimal untuk produk ini adalah $_selectedStock item.',
        );
      });
    }
  }

  Future<void> _openProductPicker() async {
    if (_loadingProducts || _products.isEmpty) {
      return;
    }

    final selectedProduct = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final searchCtrl = TextEditingController();
        final filteredProducts = List<ProductModel>.from(_products);

        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterProducts(String query) {
              final normalizedQuery = query.trim().toLowerCase();

              setModalState(() {
                filteredProducts
                  ..clear()
                  ..addAll(
                    _products.where((product) {
                      final name = product.productName.toLowerCase();
                      final description =
                          (product.description ?? '').toLowerCase();
                      return name.contains(normalizedQuery) ||
                          description.contains(normalizedQuery);
                    }),
                  );
              });
            }

            return SafeArea(
              top: false,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Produk',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_products.length} produk tersedia',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: filterProducts,
                        decoration: InputDecoration(
                          hintText: 'Cari nama produk...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 44,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Produk tidak ditemukan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Coba kata kunci lain untuk menemukan produk.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: filteredProducts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isSelected = _selected?.id == product.id;
                                final isOutOfStock = product.stock <= 0;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () =>
                                        Navigator.pop(context, product),
                                    child: Ink(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : AppColors.background,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.12)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              Icons.shopping_bag_rounded,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.productName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${product.priceFormatted} • Stok ${product.stock}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOutOfStock
                                                  ? AppColors.error
                                                      .withValues(alpha: 0.10)
                                                  : AppColors.success
                                                      .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              isOutOfStock
                                                  ? 'Habis'
                                                  : 'Tersedia',
                                              style: TextStyle(
                                                color: isOutOfStock
                                                    ? AppColors.error
                                                    : AppColors.success,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedProduct == null) {
      return;
    }

    setState(() {
      _selected = selectedProduct;
      _setQuantity(1);
    });
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_handleQuantityChanged);
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransactionBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Catat Penjualan')),
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _openProductPicker,
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _selected == null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pilih produk',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap untuk memilih produk yang terjual',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selected!.productName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_selected!.priceFormatted} • Stok $_selectedStock',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        Expanded(
                          child: Text(
                            'Harga: ${_selected!.priceFormatted} • Stok tersedia: $_selectedStock',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isOutOfStock || _isLowStock) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isOutOfStock
                            ? AppColors.error.withValues(alpha: 0.08)
                            : AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isOutOfStock
                              ? AppColors.error.withValues(alpha: 0.24)
                              : AppColors.warning.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isOutOfStock
                                ? Icons.error_outline_rounded
                                : Icons.warning_amber_rounded,
                            color: _isOutOfStock
                                ? AppColors.error
                                : AppColors.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isOutOfStock
                                  ? 'Stok produk habis. Produk ini tidak bisa dipakai untuk transaksi baru.'
                                  : 'Stok tersisa hanya $_selectedStock item. Jumlah penjualan tidak boleh melebihi stok tersedia.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _isOutOfStock
                                        ? AppColors.error
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          setState(() => _setQuantity(v - 1));
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

                        if (_selected != null && _selectedStock <= 0) {
                          _showWarningSnackBar(
                            ctx,
                            'Stok produk habis. Tidak bisa menambah jumlah.',
                          );
                          return;
                        }

                        if (_selected != null && v >= _selectedStock) {
                          _showWarningSnackBar(
                            ctx,
                            'Jumlah maksimal untuk produk ini adalah $_selectedStock item.',
                          );
                          return;
                        }

                        setState(() => _setQuantity(v + 1));
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
                        color: AppColors.success.withValues(alpha: 0.3),
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  label: _isOutOfStock
                      ? 'Stok Habis'
                      : _isLowStock
                          ? '💰 Catat Penjualan (Stok Terbatas)'
                          : '💰 Catat Penjualan',
                  onPressed: _isOutOfStock ? null : () => _submit(ctx),
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
