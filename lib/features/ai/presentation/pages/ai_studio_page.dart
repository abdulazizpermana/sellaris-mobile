import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/product_model.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/product_bloc.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/pages/ai_result_page.dart';
import 'package:sellari_umkm_frontend/core/di/service_locator.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';

class AiStudioPage extends StatelessWidget {
  const AiStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductBloc>(
      create: (_) => sl<ProductBloc>()..add(ProductLoadRequested()),
      child: const _AiStudioView(),
    );
  }
}

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
}

class _AiStudioView extends StatefulWidget {
  const _AiStudioView();

  @override
  State<_AiStudioView> createState() => _AiStudioViewState();
}

class _AiStudioViewState extends State<_AiStudioView> {
  AiStudioFeature _selectedFeature = AiStudioFeature.caption;
  ProductModel? _selectedProduct;

  void _onGenerate(BuildContext context) {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }
    context.read<ProductBloc>().add(
      ProductAiGenerateRequested(
        _selectedProduct!.id,
        _selectedProduct!.productName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sellaris AI Studio'), elevation: 0),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAiSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiResultPage(
                  aiContent: state.aiContent,
                  productName: state.productName,
                ),
              ),
            );
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            final products = state is ProductLoaded
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
                  _buildFeatureGrid(),
                  const SizedBox(height: 20),
                  _buildProductSelector(products),
                  const SizedBox(height: 20),
                  _buildActionPanel(context),
                  const SizedBox(height: 20),
                  _buildHelpSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
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
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Semua konten promosi untuk UMKM dalam satu halaman.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _StatChip(label: 'Caption', color: Colors.white),
              _StatChip(label: 'Hashtag', color: Colors.white),
              _StatChip(label: 'Marketplace', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fitur Premium', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AiStudioFeature.values.map((feature) {
            final isSelected = feature == _selectedFeature;
            return GestureDetector(
              onTap: () => setState(() => _selectedFeature = feature),
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
                child: Text(product.productName),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedProduct = value),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
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
          Text(
            'Siap untuk membuat konten?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Pilih produk lalu tekan tombol untuk membuat konten AI yang profesional dan cepat.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onGenerate(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Generate Konten Sekarang'),
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
        Text(
          'Kenapa AI Studio?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _FeatureBadge(icon: Icons.flash_on_rounded, label: 'Cepat'),
            _FeatureBadge(icon: Icons.auto_graph_rounded, label: 'Penjualan'),
            _FeatureBadge(icon: Icons.handshake_rounded, label: 'Professional'),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(right: 8),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
