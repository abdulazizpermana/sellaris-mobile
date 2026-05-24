import 'package:flutter/material.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';

class SellarisScoreCard extends StatelessWidget {
  final int score;
  final VoidCallback onDetailTap;

  const SellarisScoreCard({
    super.key,
    required this.score,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.clamp(0, 100);
    final progressValue = normalizedScore / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 6,
                    backgroundColor: AppColors.primaryLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '$normalizedScore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sellaris Score',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildScoreMessage(normalizedScore),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onDetailTap,
                  child: Text(
                    'Lihat detail',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  String _buildScoreMessage(int score) {
    if (score >= 85) {
      return 'Produkmu sudah terlihat sangat siap untuk dipasarkan. Pertahankan kualitas kontennya.';
    }
    if (score >= 70) {
      return 'Produkmu sudah cukup siap. Sedikit optimasi pada konten bisa membantu penjualan lebih maksimal.';
    }
    if (score >= 50) {
      return 'Masih ada ruang perbaikan. Lengkapi elemen promosi agar produk lebih menarik.';
    }
    return 'Produkmu butuh lebih banyak optimasi agar lebih meyakinkan calon pembeli.';
  }
}
