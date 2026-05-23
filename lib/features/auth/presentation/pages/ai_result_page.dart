// lib/features/product/presentation/pages/ai_result_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';

class AiResultPage extends StatelessWidget {
  final AiContent aiContent;
  final String productName;
  const AiResultPage({
    super.key,
    required this.aiContent,
    required this.productName,
  });

  String _titleForType(String type) {
    switch (type) {
      case 'marketplace':
        return 'Deskripsi Marketplace';
      case 'hashtag':
        return 'Hashtag';
      case 'promo':
        return 'Teks Promo WhatsApp';
      case 'smart_reply':
        return 'Balasan Cerdas';
      case 'translate':
        return 'Versi Bahasa Inggris';
      case 'caption':
      default:
        return 'Caption Instagram';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'marketplace':
        return Icons.store_outlined;
      case 'hashtag':
        return Icons.tag_rounded;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'smart_reply':
        return Icons.chat_bubble_outline_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'caption':
      default:
        return Icons.camera_alt_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'marketplace':
        return const Color(0xFFFF6900);
      case 'hashtag':
        return AppColors.primary;
      case 'promo':
        return const Color(0xFF25D366);
      case 'smart_reply':
        return const Color(0xFF6366F1);
      case 'translate':
        return AppColors.success;
      case 'caption':
      default:
        return const Color(0xFFE1306C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konten AI'),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 4),

            _ContentCard(
              icon: _iconForType(aiContent.type),
              title: _titleForType(aiContent.type),
              content: aiContent.content,
              color: _colorForType(aiContent.type),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final IconData icon;
  final String title, content;
  final Color color;
  const _ContentCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
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
          // Header
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
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title disalin! 📋'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
