// lib/features/product/presentation/pages/product_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../bloc/product_bloc.dart';
import '../../data/models/product_model.dart';
import 'add_product_page.dart';
import 'ai_result_page.dart';

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

  void _disposeControllers() {
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produk Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
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
            },
          ),
        ],
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (ctx, state) {
          if (state is ProductActionSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          if (state is ProductAiSuccess) {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => AiResultPage(
                  aiContent: state.aiContent,
                  productName: state.productName,
                ),
              ),
            );
          }
          if (state is ProductError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is ProductLoading) return _buildShimmer();
          if (state is ProductError && state is! ProductLoaded) {
            return ErrorView(
              message: state.message,
              onRetry: () =>
                  ctx.read<ProductBloc>().add(ProductLoadRequested()),
            );
          }

          final products = state is ProductLoaded
              ? state.products
              : state is ProductActionSuccess
                  ? state.products
                  : state is ProductAiSuccess
                      ? state.products
                      : <ProductModel>[];

          final filteredProducts = products.where((product) {
            final matchesSearch = product.productName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            final aiStatus =
                product.aiContent != null ? 'AI Ready' : 'Belum Generate';
            final matchesFilter = _filter == 'Semua' ||
                _filter == 'AI Ready' && aiStatus == 'AI Ready' ||
                _filter == 'Belum Generate' && aiStatus == 'Belum Generate';
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

          if (products.isEmpty) {
            return EmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada produk',
              subtitle:
                  'Tambahkan produk pertamamu dan biarkan AI bantu buatkan konten promosinya!',
              actionLabel: '+ Tambah Produk',
              onAction: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: ctx.read<ProductBloc>(),
                    child: const AddProductPage(),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ctx.read<ProductBloc>().add(ProductLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterChips(),
                const SizedBox(height: 12),
                _buildSortDropdown(),
                const SizedBox(height: 16),
                ...filteredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductCard(
                      product: product,
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari produk...',
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['Semua', 'AI Ready', 'Belum Generate'];
    return Wrap(
      spacing: 10,
      children: filters.map((label) {
        final selected = _filter == label;
        return ChoiceChip(
          label: Text(label),
          selected: selected,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _filter = label),
        );
      }).toList(),
    );
  }

  Widget _buildSortDropdown() {
    const options = ['Newest', 'Lowest Stock', 'AI Ready', 'Not Generated'];
    return Row(
      children: [
        const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: options
                .map(
                  (option) =>
                      DropdownMenuItem(value: option, child: Text(option)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _sortBy = value);
            },
          ),
        ),
      ],
    );
  }

  void _generateAi(BuildContext ctx, ProductModel product) {
    ctx.read<ProductBloc>().add(
          ProductAiGenerateRequested(
            product.id,
            product.productName,
            type: 'promo',
          ),
        );
  }

  void _confirmDelete(BuildContext ctx, ProductModel product) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?'),
        content: Text('Produk "${product.productName}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<ProductBloc>().add(ProductDeleteRequested(product.id));
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const ShimmerBox(width: 68, height: 68, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ShimmerBox(width: 140, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 90, height: 12),
                    SizedBox(height: 6),
                    ShimmerBox(width: 70, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Product Card ─────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAiTap, onDelete;
  const _ProductCard({
    required this.product,
    required this.onAiTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock <= 5;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ShimmerBox(width: 68, height: 68, radius: 12),
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceFormatted,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? AppColors.warningLight
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Stok: ${product.stock}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLowStock
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  tooltip: 'Generate AI',
                  onPressed: onAiTap,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 22,
                  ),
                  tooltip: 'Hapus',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_outlined,
            color: AppColors.primary, size: 28),
      );
}
