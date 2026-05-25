import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/core/constants/route_constants.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/user_model.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  String _selectedTone = 'Friendly';
  String _selectedMarket = 'UMKM Lokal';
  String _selectedPlatform = 'Instagram';

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<AuthBloc>().state;
    final user = userState is AuthAuthenticated ? userState.user : null;
    final profile = user?.businessProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Bisnis'),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _buildBusinessProfile(user),
            const SizedBox(height: 20),
            _buildQuickStats(profile),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Preferensi',
              subtitle: 'Atur pengalaman aplikasi agar lebih nyaman dipakai.',
            ),
            const SizedBox(height: 12),
            _buildPreferenceCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'AI Preferences',
              subtitle: 'Sesuaikan gaya AI dengan kebutuhan bisnismu.',
            ),
            const SizedBox(height: 12),
            _buildGroupedCard(
              children: [
                _buildSelectionTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Default Tone',
                  value: _selectedTone,
                  onTap: () => _showOptions(
                    title: 'Pilih Tone AI',
                    options: ['Friendly', 'Formal', 'Gen Z', 'Premium'],
                    selected: _selectedTone,
                    onSelected: (value) =>
                        setState(() => _selectedTone = value),
                  ),
                ),
                _buildDivider(),
                _buildSelectionTile(
                  icon: Icons.groups_rounded,
                  title: 'Target Market',
                  value: _selectedMarket,
                  onTap: () => _showOptions(
                    title: 'Pilih Target Market',
                    options: [
                      'UMKM Lokal',
                      'Pelanggan Online',
                      'Pembeli Milenial',
                      'Pelanggan Internasional',
                    ],
                    selected: _selectedMarket,
                    onSelected: (value) =>
                        setState(() => _selectedMarket = value),
                  ),
                ),
                _buildDivider(),
                _buildSelectionTile(
                  icon: Icons.campaign_rounded,
                  title: 'Platform Default',
                  value: _selectedPlatform,
                  onTap: () => _showOptions(
                    title: 'Pilih Platform',
                    options: ['Instagram', 'Shopee', 'Tokopedia', 'WhatsApp'],
                    selected: _selectedPlatform,
                    onSelected: (value) =>
                        setState(() => _selectedPlatform = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Data & Backup',
              subtitle: 'Kelola data bisnis dan simpan cadangan dengan aman.',
            ),
            const SizedBox(height: 12),
            _buildGroupedCard(
              children: [
                _buildActionTile(
                  icon: Icons.download_rounded,
                  title: 'Export laporan penjualan',
                  subtitle: 'Unduh data transaksi dalam format CSV',
                  onTap: () => _showMessage('Export laporan akan siap segera.'),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.cloud_upload_rounded,
                  title: 'Backup data',
                  subtitle: 'Simpan data produk dan transaksi secara lokal',
                  onTap: () => _showMessage('Backup data berhasil disimpan.'),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.sync_rounded,
                  title: 'Sinkronisasi Cloud',
                  subtitle: 'Jaga data tetap aman di semua perangkat',
                  onTap: () =>
                      _showMessage('Cloud sync sedang dalam pengembangan.'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Bantuan',
              subtitle: 'Informasi penting dan bantuan penggunaan aplikasi.',
            ),
            const SizedBox(height: 12),
            _buildGroupedCard(
              children: [
                _buildActionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'FAQ',
                  subtitle: 'Pertanyaan umum tentang Sellaris',
                  onTap: () => _showMessage('Buka FAQ'),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Sellaris',
                  subtitle: 'Versi aplikasi dan nilai jual utama',
                  onTap: () => _showMessage(
                    'Sellaris adalah AI Growth Assistant untuk UMKM.',
                  ),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan Privasi',
                  subtitle: 'Privasi data kamu penting bagi kami',
                  onTap: () =>
                      _showMessage('Kebijakan Privasi tersedia di website.'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Akun',
              subtitle: 'Kelola akses akun Sellaris milikmu.',
            ),
            const SizedBox(height: 12),
            _buildGroupedCard(
              children: [
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Keluar',
                  subtitle: 'Keluar dari akun Sellaris UMKM',
                  onTap: _confirmLogout,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessProfile(UserModel? user) {
    final profile = user?.businessProfile;

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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
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
                      profile?.businessName ?? user?.name ?? 'Sellaris UMKM',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.category ?? 'UMKM',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile?.description ??
                        'Lengkapi profil bisnismu untuk hasil AI yang lebih relevan dan personal.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          height: 1.45,
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

  Widget _buildQuickStats(BusinessProfile? profile) {
    final category =
        profile?.category.isNotEmpty == true ? profile!.category : 'UMKM';
    final phone =
        profile?.phone?.isNotEmpty == true ? profile!.phone! : 'Belum diatur';
    final status = _notificationsEnabled ? 'Aktif' : 'Nonaktif';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.category_rounded,
            label: 'Kategori',
            value: category,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.phone_outlined,
            label: 'Kontak',
            value: phone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.notifications_active_outlined,
            label: 'Notif',
            value: status,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard() {
    return _buildGroupedCard(
      children: [
        SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          value: _notificationsEnabled,
          title: const Text('Notifikasi'),
          subtitle: const Text('Terima pengingat dan update penting'),
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildGroupedCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withValues(alpha: 0.8),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _buildLeadingIcon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final accentColor = isDestructive ? AppColors.error : AppColors.primary;
    final accentBackground = isDestructive
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.primaryLight;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accentBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: accentColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDestructive ? AppColors.error : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLeadingIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }

  void _showOptions({
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih pengaturan yang paling sesuai untuk bisnismu.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) {
                final isSelected = option == selected;
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: option,
                    groupValue: selected,
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      option,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        onSelected(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
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
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Keluar dari akun?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu akan keluar dari akun Sellaris di perangkat ini. Masuk kembali diperlukan untuk melanjutkan.',
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
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
