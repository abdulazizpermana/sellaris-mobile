import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../auth/data/models/product_model.dart';
import '../../../auth/presentation/bloc/product_bloc.dart';
import '../../../auth/presentation/pages/add_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductModel _product;
  AiContentHistory? _history;
  bool _isHistoryLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    context.read<ProductBloc>().add(ProductAiHistoryRequested(_product.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _product.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _openEditPage,
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Produk',
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            tooltip: 'Hapus Produk',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductAiHistoryLoaded) {
            final refreshedProduct =
                _findProductById(state.products, _product.id);
            if (refreshedProduct != null) {
              _product = refreshedProduct;
            }

            setState(() {
              _history = state.history;
              _isHistoryLoading = false;
            });
          }

          if (state is ProductAiAllSuccess &&
              state.productName == _product.productName) {
            setState(() => _isGenerating = false);
            context
                .read<ProductBloc>()
                .add(ProductAiHistoryRequested(_product.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konten AI berhasil diperbarui ✨'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
              ),
            );
          }

          if (state is ProductActionSuccess) {
            final updatedProduct =
                _findProductById(state.products, _product.id);
            if (updatedProduct == null) {
              Navigator.pop(context, true);
              return;
            }

            setState(() {
              _product = updatedProduct;
            });
          }

          if (state is ProductError) {
            if (_isGenerating) {
              setState(() => _isGenerating = false);
            }

            if (_isHistoryLoading) {
              setState(() => _isHistoryLoading = false);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildHeroSection(),
              const SizedBox(height: 16),
              _buildInfoCard(context),
              const SizedBox(height: 16),
              _buildActionRow(context),
              const SizedBox(height: 24),
              _buildAiSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _product.imageUrl?.isNotEmpty == true
              ? CachedNetworkImage(
                  imageUrl: _product.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerBox(
                    width: double.infinity,
                    height: 220,
                    radius: 0,
                  ),
                  errorWidget: (context, url, error) => _buildHeroPlaceholder(),
                )
              : _buildHeroPlaceholder(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x330F172A),
                  Color(0xCC0F172A),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _product.priceFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildHeroPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 52,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final hasDescription = _product.description?.trim().isNotEmpty == true;
    final hasTargetMarket = _product.targetMarket?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoStat(
                  label: 'Stok',
                  value: _product.stock.toString(),
                  icon: Icons.inventory_2_outlined,
                  valueColor: _product.stock <= 5
                      ? AppColors.warning
                      : AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Status',
                  value: _product.isActive ? 'Aktif' : 'Nonaktif',
                  icon: _product.isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  valueColor: _product.isActive
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: _InfoStat(
                  label: 'Target Market',
                  value: hasTargetMarket ? _product.targetMarket! : '-',
                  icon: Icons.groups_2_outlined,
                ),
              ),
            ],
          ),
          if (hasDescription) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            Text(
              'Deskripsi Produk',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _product.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _isGenerating ? null : _generateAgain,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('✨ Generate Ulang'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _openEditPage,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('✏️ Edit Produk'),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSection(BuildContext context) {
    final cards = _buildContentCards();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konten AI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        if (_isHistoryLoading)
          const _AiHistoryShimmer()
        else if (_history == null || !_history!.hasAnyContent)
          _buildEmptyAiState(context)
        else ...[
          ...cards,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copyAllContent,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Salin Semua'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyAiState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada konten AI',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Generate untuk membuat konten',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentCards() {
    final history = _history;
    if (history == null) return const [];

    final items = <_AiContentItem>[
      _AiContentItem(
        title: '📸 Caption Instagram',
        type: 'caption',
        content: history.caption,
        color: const Color(0xFFE1306C),
      ),
      _AiContentItem(
        title: '#️⃣ Hashtag',
        type: 'hashtag',
        content: history.hashtag,
        color: AppColors.primary,
      ),
      _AiContentItem(
        title: '🛒 Deskripsi Marketplace',
        type: 'marketplace',
        content: history.marketplace,
        color: const Color(0xFFFF6900),
      ),
      _AiContentItem(
        title: '📢 Teks Promo',
        type: 'promo',
        content: history.promo,
        color: const Color(0xFF25D366),
      ),
      _AiContentItem(
        title: '🌐 Versi Inggris',
        type: 'translate',
        content: history.translate,
        color: AppColors.success,
      ),
      _AiContentItem(
        title: '💬 Smart Reply',
        type: 'smart_reply',
        content: history.smartReply,
        color: const Color(0xFF6366F1),
      ),
    ];

    return items
        .where((item) => item.content?.trim().isNotEmpty == true)
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AiContentCard(
              item: item,
              onCopy: () => _copySingleContent(item.title, item.content!),
            ),
          ),
        )
        .toList();
  }

  void _generateAgain() {
    setState(() => _isGenerating = true);
    context.read<ProductBloc>().add(
          ProductAiGenerateAllRequested(_product.id, _product.productName),
        );
  }

  Future<void> _copySingleContent(String title, String content) async {
    await Clipboard.setData(ClipboardData(text: content));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title disalin! 📋'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyAllContent() async {
    final history = _history;
    if (history == null) return;

    final sections = <String>[
      if (history.caption?.trim().isNotEmpty == true)
        '=== CAPTION INSTAGRAM ===\n${history.caption!}',
      if (history.hashtag?.trim().isNotEmpty == true)
        '=== HASHTAG ===\n${history.hashtag!}',
      if (history.marketplace?.trim().isNotEmpty == true)
        '=== DESKRIPSI MARKETPLACE ===\n${history.marketplace!}',
      if (history.promo?.trim().isNotEmpty == true)
        '=== TEKS PROMO ===\n${history.promo!}',
      if (history.translate?.trim().isNotEmpty == true)
        '=== VERSI INGGRIS ===\n${history.translate!}',
      if (history.smartReply?.trim().isNotEmpty == true)
        '=== SMART REPLY ===\n${history.smartReply!}',
    ];

    await Clipboard.setData(ClipboardData(text: sections.join('\n\n')));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua konten berhasil disalin! 📋'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openEditPage() async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: AddProductPage(product: _product),
        ),
      ),
    );

    if (refreshed == true && mounted) {
      context.read<ProductBloc>().add(ProductLoadRequested());
      context.read<ProductBloc>().add(ProductAiHistoryRequested(_product.id));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus produk?'),
            content: Text(
              'Produk "${_product.productName}" akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    context.read<ProductBloc>().add(ProductDeleteRequested(_product.id));
  }

  ProductModel? _findProductById(List<ProductModel> products, int id) {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AiHistoryShimmer extends StatelessWidget {
  const _AiHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBox(width: double.infinity, height: 132, radius: 18),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 132, radius: 18),
        SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 132, radius: 18),
      ],
    );
  }
}

class _AiContentItem {
  final String title;
  final String type;
  final String? content;
  final Color color;

  const _AiContentItem({
    required this.title,
    required this.type,
    required this.content,
    required this.color,
  });
}

class _AiContentCard extends StatelessWidget {
  final _AiContentItem item;
  final VoidCallback onCopy;

  const _AiContentCard({
    required this.item,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  style: TextButton.styleFrom(
                    foregroundColor: item.color,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('Salin'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ExpandableText(
              text: item.content ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.65,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  bool _canExpand = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureText();
  }

  @override
  void didUpdateWidget(covariant ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.maxLines != widget.maxLines) {
      _expanded = false;
      _measureText();
    }
  }

  void _measureText() {
    final painter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: widget.maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: MediaQuery.of(context).size.width - 76);

    final canExpand = painter.didExceedMaxLines;
    if (canExpand != _canExpand && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _canExpand = canExpand);
        }
      });
    } else {
      _canExpand = canExpand;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: _expanded ? null : widget.maxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        if (_canExpand) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Sembunyikan' : 'Lihat selengkapnya',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
