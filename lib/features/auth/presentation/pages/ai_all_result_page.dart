// lib/features/product/presentation/pages/ai_all_result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';

class AiAllResultPage extends StatefulWidget {
  final AiAllContent aiContent;
  final String productName;
  final Future<void> Function()? onRefresh;

  const AiAllResultPage({
    super.key,
    required this.aiContent,
    required this.productName,
    this.onRefresh,
  });

  @override
  State<AiAllResultPage> createState() => _AiAllResultPageState();
}

class _AiAllResultPageState extends State<AiAllResultPage> {
  bool _isRefreshing = false;

  List<_AiSectionData> get _sections => [
        _AiSectionData(
          title: 'Caption Instagram',
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFE1306C),
          content: widget.aiContent.caption,
        ),
        _AiSectionData(
          title: 'Hashtag',
          icon: Icons.tag_rounded,
          color: AppColors.primary,
          content: widget.aiContent.hashtag,
        ),
        _AiSectionData(
          title: 'Deskripsi Marketplace',
          icon: Icons.store_outlined,
          color: const Color(0xFFFF6900),
          content: widget.aiContent.marketplace,
        ),
        _AiSectionData(
          title: 'Teks Promo',
          icon: Icons.campaign_outlined,
          color: const Color(0xFF25D366),
          content: widget.aiContent.promo,
        ),
        _AiSectionData(
          title: 'Versi Bahasa Inggris',
          icon: Icons.translate_rounded,
          color: AppColors.success,
          content: widget.aiContent.translate,
        ),
        _AiSectionData(
          title: 'Smart Reply',
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF6366F1),
          content: widget.aiContent.smartReply,
        ),
      ].where((section) => section.hasContent).toList();

  String get _allContentText {
    final buffer = StringBuffer();

    for (final section in _sections) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.writeln(section.title);
      buffer.writeln(section.content!.trim());
    }

    return buffer.toString().trim();
  }

  Future<void> _copyText(String title, String content) async {
    await Clipboard.setData(ClipboardData(text: content));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title disalin! 📋'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _copyAll() async {
    if (_sections.isEmpty) return;
    await _copyText('Semua konten', _allContentText);
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null || _isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Konten AI - ${widget.productName}'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI Generated',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sections.isEmpty ? null : _copyAll,
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Salin Semua'),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _HeaderCard(
              productName: widget.productName,
              sectionCount: _sections.length,
              isRefreshing: _isRefreshing,
            ),
            const SizedBox(height: 16),
            if (_sections.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Belum ada konten AI yang berhasil dibuat untuk produk ini.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ..._sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ContentCard(
                    icon: section.icon,
                    title: section.title,
                    content: section.content!,
                    color: section.color,
                    onCopy: () => _copyText(section.title, section.content!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String productName;
  final int sectionCount;
  final bool isRefreshing;

  const _HeaderCard({
    required this.productName,
    required this.sectionCount,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isRefreshing
                      ? 'Sedang generate ulang konten AI...'
                      : '$sectionCount jenis konten AI berhasil dibuat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.92),
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

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final VoidCallback onCopy;

  const _ContentCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Salin',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSectionData {
  final String title;
  final IconData icon;
  final Color color;
  final String? content;

  const _AiSectionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  bool get hasContent => content != null && content!.trim().isNotEmpty;
}
