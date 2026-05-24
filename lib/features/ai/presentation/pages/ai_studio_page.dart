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
      print('=== SELECTED FEATURE: ${_selectedFeature.apiType} ===');
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

    // ← Kirim apiType dari feature yang dipilih
    context.read<ProductBloc>().add(
          ProductAiGenerateRequested(
            _selectedProduct!.id,
            _selectedProduct!.productName,
            type: _selectedFeature.apiType, // ← INI YANG FIX MASALAHNYA!
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sellaris AI Studio'), elevation: 0),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAiSuccess) {
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
          final products = state is ProductLoaded
              ? state.products
              : state is ProductActionSuccess
                  ? state.products
                  : <ProductModel>[];

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
                _buildProductSelector(products),
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
              color: Colors.white.withOpacity(0.2),
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
        Text('Pilih Fitur', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AiStudioFeature.values.map((feature) {
            final isSelected = feature == _selectedFeature;
            return GestureDetector(
              onTap: isLoading
                  ? null
                  : () => setState(
                      () => _selectedFeature = feature), // ← update state
              child: Container(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      feature.icon,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      feature.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      feature.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProductSelector(List<ProductModel> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Produk', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<ProductModel>(
            value: _selectedProduct,
            underline: const SizedBox(),
            isExpanded: true,
            hint: const Text('Pilih produk untuk dibuat konten AI'),
            items: products.map((product) {
              return DropdownMenuItem(
                value: product,
                child: Text(
                  product.productName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedProduct = value),
          ),
        ),

        // Preview produk yang dipilih
        if (_selectedProduct != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_selectedProduct!.productName} • ${_selectedProduct!.priceFormatted}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ]),
          ),
        ],
      ],
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
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Generate ${_selectedFeature.title}'),
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
        Row(
          children: const [
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
