// lib/features/auth/presentation/pages/ai_studio_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/product_model.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/product_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/pages/ai_result_page.dart';
import 'package:sellari_umkm_frontend/core/di/service_locator.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';

class AiStudioPage extends StatelessWidget {
  final String? preSelectedFeature;

  const AiStudioPage({super.key, this.preSelectedFeature});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductBloc>(
      create: (_) => sl<ProductBloc>()..add(ProductLoadRequested()),
      child: _AiStudioView(
        preSelectedFeature: preSelectedFeature,
      ),
    );
  }
}

// ─── Feature Enum ─────────────────────────────────────────────
enum AiStudioFeature {
  caption,
  marketplace,
  hashtags,
  promo,
  smartReply,
  translation,
}

extension AiStudioFeatureLabel on AiStudioFeature {
  String get title {
    switch (this) {
      case AiStudioFeature.caption:
        return 'Caption Instagram';
      case AiStudioFeature.marketplace:
        return 'Deskripsi Marketplace';
      case AiStudioFeature.hashtags:
        return 'Hashtag Generator';
      case AiStudioFeature.promo:
        return 'Promo Campaign';
      case AiStudioFeature.smartReply:
        return 'Smart Reply';
      case AiStudioFeature.translation:
        return 'Terjemahan EN';
    }
  }

  String get subtitle {
    switch (this) {
      case AiStudioFeature.caption:
        return 'Teks jualan yang menarik untuk Instagram.';
      case AiStudioFeature.marketplace:
        return 'Deskripsi produk untuk Shopee/Tokopedia.';
      case AiStudioFeature.hashtags:
        return 'Hashtag yang relevan dan viral.';
      case AiStudioFeature.promo:
        return 'Copy promo untuk diskon dan flash sale.';
      case AiStudioFeature.smartReply:
        return 'Balasan cepat untuk pelanggan.';
      case AiStudioFeature.translation:
        return 'Terjemahkan deskripsi ke Bahasa Inggris.';
    }
  }

  IconData get icon {
    switch (this) {
      case AiStudioFeature.caption:
        return Icons.camera_alt_outlined;
      case AiStudioFeature.marketplace:
        return Icons.store_outlined;
      case AiStudioFeature.hashtags:
        return Icons.tag_rounded;
      case AiStudioFeature.promo:
        return Icons.local_offer_outlined;
      case AiStudioFeature.smartReply:
        return Icons.chat_bubble_outline;
      case AiStudioFeature.translation:
        return Icons.translate_rounded;
    }
  }

  // ← MAPPING KE API TYPE — INI KUNCINYA!
  String get apiType {
    switch (this) {
      case AiStudioFeature.caption:
        return 'caption';
      case AiStudioFeature.marketplace:
        return 'marketplace';
      case AiStudioFeature.hashtags:
        return 'hashtag';
      case AiStudioFeature.promo:
        return 'promo';
      case AiStudioFeature.smartReply:
        return 'smart_reply';
      case AiStudioFeature.translation:
        return 'translate';
    }
  }
}

// ─── View ─────────────────────────────────────────────────────
class _AiStudioView extends StatefulWidget {
  final String? preSelectedFeature;

  const _AiStudioView({this.preSelectedFeature});

  @override
  State<_AiStudioView> createState() => _AiStudioViewState();
}

class _AiStudioViewState extends State<_AiStudioView> {
  late AiStudioFeature _selectedFeature;
  ProductModel? _selectedProduct;
  bool _isLoadingDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedFeature = _mapToFeature(widget.preSelectedFeature);
  }

  AiStudioFeature _mapToFeature(String? type) {
    switch (type) {
      case 'marketplace':
        return AiStudioFeature.marketplace;
      case 'promo':
        return AiStudioFeature.promo;
      case 'hashtag':
        return AiStudioFeature.hashtags;
      case 'smart_reply':
        return AiStudioFeature.smartReply;
      case 'translate':
        return AiStudioFeature.translation;
      case 'caption':
      default:
        return AiStudioFeature.caption;
    }
  }

  void _onGenerate(BuildContext context) {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih produk terlebih dahulu'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    _showLoadingDialog(context);

    context.read<ProductBloc>().add(
          ProductAiGenerateRequested(
            _selectedProduct!.id,
            _selectedProduct!.productName,
            type: _selectedFeature.apiType,
          ),
        );
  }

  void _showLoadingDialog(BuildContext context) {
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
                    'AI sedang menyiapkan ${_selectedFeature.title.toLowerCase()} untuk ${_selectedProduct!.productName}.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sellaris AI Studio'), elevation: 0),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAiSuccess) {
            _hideLoadingDialog(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiResultPage(
                  aiContent: state.aiContent,
                  productName: state.productName,
                  selectedType: state.selectedType,
                ),
              ),
            );
          } else if (state is ProductError) {
            _hideLoadingDialog(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProductLoading;
          final products = _extractProducts(state);

          _syncSelectedProduct(products);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                context.read<ProductBloc>().add(ProductLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHero(context),
                const SizedBox(height: 20),
                _buildFeatureGrid(isLoading),
                const SizedBox(height: 20),
                _buildProductSelector(products, isLoading),
                const SizedBox(height: 20),
                _buildActionPanel(context, isLoading),
                const SizedBox(height: 20),
                _buildHelpSection(context),
                const SizedBox(height: 24),
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

    if (state is ProductError) {
      return state.products;
    }

    return <ProductModel>[];
  }

  void _syncSelectedProduct(List<ProductModel> products) {
    if (_selectedProduct == null) {
      return;
    }

    final selectedProductId = _selectedProduct!.id;

    for (final product in products) {
      if (product.id == selectedProductId) {
        if (!identical(product, _selectedProduct)) {
          _selectedProduct = product;
        }
        return;
      }
    }

    _selectedProduct = null;
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Sellaris AI Studio',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Semua konten promosi untuk UMKM dalam satu halaman.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),

          // Chip fitur yang dipilih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_selectedFeature.icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Dipilih: ${_selectedFeature.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Fitur AI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih jenis konten yang ingin dibuat. Card dibuat lebih rapi agar mudah dipilih dan nyaman dibaca.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AiStudioFeature.values.map((feature) {
                final isSelected = feature == _selectedFeature;

                return SizedBox(
                  width: itemWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: isLoading
                          ? null
                          : () => setState(() => _selectedFeature = feature),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.4 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : Colors.black.withValues(alpha: 0.035),
                              blurRadius: isSelected ? 18 : 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    feature.icon,
                                    size: 21,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.background,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              feature.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feature.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.82)
                                        : AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.14)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isSelected
                                    ? 'Sedang dipilih'
                                    : 'Tap untuk pilih',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductSelector(List<ProductModel> products, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Produk',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih produk yang ingin dibuatkan konten AI agar hasilnya lebih relevan dengan usaha kamu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: products.isEmpty || isLoading
                ? null
                : () async {
                    final selectedProduct =
                        await showModalBottomSheet<ProductModel>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetContext) {
                        return _ProductSelectionSheet(
                          products: products,
                          selectedProduct: _selectedProduct,
                        );
                      },
                    );

                    if (selectedProduct != null && mounted) {
                      setState(() => _selectedProduct = selectedProduct);
                    }
                  },
            child: AbsorbPointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isLoading
                      ? AppColors.background.withValues(alpha: 0.7)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedProduct?.productName ??
                            (products.isEmpty
                                ? 'Belum ada produk tersedia'
                                : 'Pilih produk untuk dibuat konten AI'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedProduct != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: _selectedProduct != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: products.isEmpty || isLoading
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedProduct != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProduct!.productName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedProduct!.priceFormatted,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Siap untuk membuat konten?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Fitur: ${_selectedFeature.title}\nPilih produk lalu tekan tombol untuk membuat konten AI.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : () => _onGenerate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.auto_awesome_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLoading
                        ? 'Menyiapkan konten...'
                        : 'Generate ${_selectedFeature.title}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kenapa AI Studio?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
                child: _FeatureBadge(
                    icon: Icons.flash_on_rounded, label: 'Cepat')),
            SizedBox(width: 8),
            Expanded(
                child: _FeatureBadge(
                    icon: Icons.auto_graph_rounded, label: 'Penjualan')),
            SizedBox(width: 8),
            Expanded(
                child: _FeatureBadge(
                    icon: Icons.handshake_rounded, label: 'Professional')),
          ],
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────
class _ProductSelectionSheet extends StatelessWidget {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;

  const _ProductSelectionSheet({
    required this.products,
    required this.selectedProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
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
                    child: Text(
                      'Pilih Produk',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Belum ada produk yang tersedia untuk dipilih.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = selectedProduct?.id == product.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context, product),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.priceFormatted,
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
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.chevron_right_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ],
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
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
