import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../data/models/product_model.dart';
import '../bloc/product_bloc.dart';
import 'add_product_page.dart';
import 'ai_all_result_page.dart';
import 'ai_result_page.dart';
import '../../../product/presentation/pages/product_detail_page.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductBloc>()..add(ProductLoadRequested()),
      child: const _ProductView(),
    );
  }
}

class _ProductView extends StatefulWidget {
  const _ProductView();

  @override
  State<_ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<_ProductView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortBy = 'Newest';
  String _filter = 'Semua';
  int? _generatingProductId;
  bool _isLoadingDialogVisible = false;
  bool _isAiQuotaDialogVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produk Saya'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filledTonal(
              onPressed: () => _openAddProductPage(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tambah Produk',
            ),
          ),
        ],
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (ctx, state) {
          if (state is ProductActionSuccess) {
            _showSnackBar(
              ctx,
              message: state.message,
              backgroundColor: AppColors.success,
            );
          }

          if (state is ProductAiSuccess) {
            _hideLoadingDialog(ctx);
            setState(() => _generatingProductId = null);
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => AiResultPage(
                  aiContent: state.aiContent,
                  productName: state.productName,
                  selectedType: state.selectedType,
                ),
              ),
            );
          }

          if (state is ProductAiAllSuccess) {
            _hideLoadingDialog(ctx);
            setState(() => _generatingProductId = null);
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<ProductBloc>(),
                  child: AiAllResultPage(
                    aiContent: state.aiContent,
                    productName: state.productName,
                    onRefresh: () async {
                      final productId = _findProductIdByName(
                        state.products,
                        state.productName,
                      );

                      if (productId == null) {
                        return;
                      }

                      ctx.read<ProductBloc>().add(
                            ProductAiGenerateAllRequested(
                              productId,
                              state.productName,
                            ),
                          );
                    },
                  ),
                ),
              ),
            );
          }

          if (state is ProductError) {
            _hideLoadingDialog(ctx);
            setState(() => _generatingProductId = null);

            if (_isAiQuotaError(state.message)) {
              _showAiQuotaDialog(
                ctx,
                message: state.message,
              );
            } else {
              _showSnackBar(
                ctx,
                message: state.message,
                backgroundColor: AppColors.error,
              );
            }
          }
        },
        builder: (ctx, state) {
          if (state is ProductLoading) {
            return _buildShimmer();
          }

          if (state is ProductError && state.products.isEmpty) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  ctx.read<ProductBloc>().add(ProductLoadRequested()),
            );
          }

          final products = _extractProducts(state);
          final filteredProducts = _buildFilteredProducts(products);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ctx.read<ProductBloc>().add(ProductLoadRequested());
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _buildOverviewCard(products),
                const SizedBox(height: 20),
                _buildControlPanel(products.length, filteredProducts.length),
                const SizedBox(height: 20),
                if (products.isEmpty)
                  _buildEmptyState(ctx)
                else if (filteredProducts.isEmpty)
                  _buildNoResultState()
                else
                  ...filteredProducts.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProductCard(
                        product: product,
                        isGeneratingAi: _generatingProductId == product.id,
                        onTap: () => _openProductDetailPage(ctx, product),
                        onEdit: () => _openEditProductPage(ctx, product),
                        onAiTap: () => _generateAi(ctx, product),
                        onDelete: () => _confirmDelete(ctx, product),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<ProductModel> _extractProducts(ProductState state) {
    if (state is ProductLoaded) {
      return state.products;
    }

    if (state is ProductRefreshing) {
      return state.products;
    }

    if (state is ProductActionSuccess) {
      return state.products;
    }

    if (state is ProductAiSuccess) {
      return state.products;
    }

    if (state is ProductAiAllSuccess) {
      return state.products;
    }

    if (state is ProductAiHistoryLoaded) {
      return state.products;
    }

    if (state is ProductError) {
      return state.products;
    }

    return <ProductModel>[];
  }

  List<ProductModel> _buildFilteredProducts(List<ProductModel> products) {
    final filteredProducts = products.where((product) {
      final matchesSearch = product.productName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final aiStatus =
          product.aiContent != null ? 'AI Ready' : 'Belum Generate';
      final matchesFilter = _filter == 'Semua' ||
          (_filter == 'AI Ready' && aiStatus == 'AI Ready') ||
          (_filter == 'Belum Generate' && aiStatus == 'Belum Generate');

      return matchesSearch && matchesFilter;
    }).toList();

    filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'Lowest Stock':
          return a.stock.compareTo(b.stock);
        case 'AI Ready':
          return (b.aiContent != null ? 1 : 0).compareTo(
            a.aiContent != null ? 1 : 0,
          );
        case 'Not Generated':
          return (a.aiContent == null ? 1 : 0).compareTo(
            b.aiContent == null ? 1 : 0,
          );
        default:
          return b.id.compareTo(a.id);
      }
    });

    return filteredProducts;
  }

  Widget _buildOverviewCard(List<ProductModel> products) {
    final totalProducts = products.length;
    final aiReadyCount =
        products.where((product) => product.aiContent != null).length;
    final lowStockCount =
        products.where((product) => product.stock <= 5).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Produk',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola produk, stok, dan konten AI dengan tampilan yang lebih rapi.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroMetric(
                icon: Icons.grid_view_rounded,
                label: 'Total',
                value: '$totalProducts Produk',
              ),
              _buildHeroMetric(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Ready',
                value: '$aiReadyCount Produk',
              ),
              _buildHeroMetric(
                icon: Icons.warning_amber_rounded,
                label: 'Stok Rendah',
                value: '$lowStockCount Produk',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _openAddProductPage(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Tambah Produk Baru'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(int totalCount, int visibleCount) {
    return Container(
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
            'Temukan Produk',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cari, filter, dan urutkan produk agar pengelolaan lebih cepat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Text(
            'Filter Status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildSortDropdown(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Menampilkan $visibleCount dari $totalCount produk',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari nama produk',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['Semua', 'AI Ready', 'Belum Generate'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final selected = _filter == label;

        return ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: AppColors.primaryLight,
          backgroundColor: AppColors.background,
          side: BorderSide(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.24)
                : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _filter = label),
        );
      }).toList(),
    );
  }

  Widget _buildSortDropdown() {
    const options = ['Newest', 'Lowest Stock', 'AI Ready', 'Not Generated'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urutkan',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _sortBy,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.sort_rounded,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _sortBy = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk pertamamu agar Sellaris bisa membantu membuat konten AI dan mengelola stok lebih rapi.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _openAddProductPage(ctx),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Tambah Produk'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Produk tidak ditemukan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci pencarian, filter, atau urutan produk.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openAddProductPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: const AddProductPage(),
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<ProductBloc>().add(ProductLoadRequested());
    }
  }

  void _openEditProductPage(BuildContext context, ProductModel product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: AddProductPage(product: product),
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<ProductBloc>().add(ProductLoadRequested());
    }
  }

  void _generateAi(BuildContext ctx, ProductModel product) {
    setState(() => _generatingProductId = product.id);
    _showLoadingDialog(ctx, product.productName);
    ctx.read<ProductBloc>().add(
          ProductAiGenerateAllRequested(
            product.id,
            product.productName,
          ),
        );
  }

  void _showLoadingDialog(BuildContext context, String productName) {
    if (_isLoadingDialogVisible) {
      return;
    }

    _isLoadingDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sedang membuat konten...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI sedang menyiapkan konten untuk $productName.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Mohon tunggu beberapa saat',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isLoadingDialogVisible = false;
    });
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!_isLoadingDialogVisible || !mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
  }

  int? _findProductIdByName(List<ProductModel> products, String productName) {
    for (final product in products) {
      if (product.productName == productName) {
        return product.id;
      }
    }

    return null;
  }

  void _confirmDelete(BuildContext ctx, ProductModel product) {
    showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus produk?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Produk "${product.productName}" akan dihapus permanen dari daftar produk kamu.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                        ctx.read<ProductBloc>().add(
                              ProductDeleteRequested(product.id),
                            );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 180, height: 22, radius: 10),
              SizedBox(height: 10),
              ShimmerBox(width: 240, height: 14, radius: 10),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: ShimmerBox(width: 0, height: 56, radius: 16)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(width: 0, height: 56, radius: 16)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerBox(width: 0, height: 56, radius: 16)),
                ],
              ),
              SizedBox(height: 18),
              ShimmerBox(width: double.infinity, height: 48, radius: 14),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(18),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 130, height: 18, radius: 10),
              SizedBox(height: 8),
              ShimmerBox(width: 220, height: 14, radius: 10),
              SizedBox(height: 18),
              ShimmerBox(width: double.infinity, height: 54, radius: 16),
              SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ShimmerBox(width: 90, height: 34, radius: 20),
                  ShimmerBox(width: 110, height: 34, radius: 20),
                  ShimmerBox(width: 130, height: 34, radius: 20),
                ],
              ),
              SizedBox(height: 14),
              ShimmerBox(width: double.infinity, height: 54, radius: 16),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 76, height: 76, radius: 18),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 150, height: 18, radius: 10),
                          SizedBox(height: 10),
                          ShimmerBox(width: 100, height: 16, radius: 10),
                          SizedBox(height: 10),
                          ShimmerBox(width: 190, height: 12, radius: 10),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              ShimmerBox(width: 88, height: 28, radius: 20),
                              SizedBox(width: 8),
                              ShimmerBox(width: 100, height: 28, radius: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ShimmerBox(width: double.infinity, height: 1, radius: 0),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBox(width: 0, height: 46, radius: 14),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ShimmerBox(width: 0, height: 46, radius: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openProductDetailPage(
    BuildContext context,
    ProductModel product,
  ) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: ProductDetailPage(product: product),
        ),
      ),
    );

    if (shouldRefresh == true && context.mounted) {
      context.read<ProductBloc>().add(ProductLoadRequested());
    }
  }

  bool _isAiQuotaError(String message) {
    final normalized = message.toLowerCase();

    const keywords = [
      'limit harian',
      'limit menit',
      'silakan coba lagi besok',
      'quota exceeded',
      'rate limit',
      '429',
      'exhausted',
      'resource has been exhausted',
      'too many requests',
      'rpm',
      'rpd',
    ];

    return keywords.any((keyword) => normalized.contains(keyword));
  }

  String _aiQuotaDialogTitle(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('limit harian') ||
        normalized.contains('silakan coba lagi besok') ||
        normalized.contains('rpd')) {
      return 'Kuota Harian AI Tercapai';
    }

    if (normalized.contains('limit menit') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests') ||
        normalized.contains('rpm')) {
      return 'Batas Permintaan AI Tercapai';
    }

    return 'Kuota AI Sedang Penuh';
  }

  String _aiQuotaDialogHint(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('limit harian') ||
        normalized.contains('silakan coba lagi besok') ||
        normalized.contains('rpd')) {
      return 'Silakan coba lagi besok saat kuota harian Gemini tersedia kembali.';
    }

    return 'Tunggu beberapa saat lalu coba generate lagi saat kuota tersedia.';
  }

  void _showAiQuotaDialog(
    BuildContext context, {
    required String message,
  }) {
    if (_isAiQuotaDialogVisible || !mounted) {
      return;
    }

    _isAiQuotaDialogVisible = true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.warning,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _aiQuotaDialogTitle(message),
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiQuotaDialogHint(message),
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isAiQuotaDialogVisible = false;
    });
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isGeneratingAi;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onAiTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isGeneratingAi,
    required this.onTap,
    required this.onEdit,
    required this.onAiTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock <= 5;
    final hasAiContent = product.aiContent != null;
    final hasDescription = product.description?.trim().isNotEmpty == true;
    final hasTargetMarket = product.targetMarket?.trim().isNotEmpty == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLowStock
                  ? AppColors.warning.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerBox(
                                width: 76,
                                height: 76,
                                radius: 18,
                              ),
                              errorWidget: (context, url, error) =>
                                  _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.priceFormatted,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          if (hasDescription) ...[
                            const SizedBox(height: 8),
                            Text(
                              product.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ProductTag(
                                icon: Icons.inventory_2_outlined,
                                label: 'Stok ${product.stock}',
                                backgroundColor: isLowStock
                                    ? AppColors.warningLight
                                    : AppColors.successLight,
                                textColor: isLowStock
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              _ProductTag(
                                icon: hasAiContent
                                    ? Icons.auto_awesome_rounded
                                    : Icons.schedule_rounded,
                                label: hasAiContent
                                    ? 'AI Ready'
                                    : 'Belum Generate',
                                backgroundColor: hasAiContent
                                    ? AppColors.primaryLight
                                    : AppColors.background,
                                textColor: hasAiContent
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              _ProductTag(
                                icon: product.isActive
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.pause_circle_outline_rounded,
                                label: product.isActive ? 'Aktif' : 'Nonaktif',
                                backgroundColor: product.isActive
                                    ? AppColors.successLight
                                    : AppColors.background,
                                textColor: product.isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                          if (hasTargetMarket) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.groups_2_outlined,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Target: ${product.targetMarket!}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isGeneratingAi ? null : onAiTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isGeneratingAi
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      isGeneratingAi ? 'Membuat...' : 'Generate AI',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }
}

class _ProductTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _ProductTag({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
