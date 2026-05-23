import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellari_umkm_frontend/core/theme/app_theme.dart';
import 'package:sellari_umkm_frontend/core/theme/theme_cubit.dart';
import 'package:sellari_umkm_frontend/core/widgets/shared_widgets.dart';
import 'package:sellari_umkm_frontend/features/auth/data/models/user_model.dart';
import 'package:sellari_umkm_frontend/features/auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Indonesia';
  String _selectedTone = 'Friendly';
  String _selectedMarket = 'UMKM Lokal';
  String _selectedPlatform = 'Instagram';

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<AuthBloc>().state;
    final user = userState is AuthAuthenticated ? userState.user : null;
    final themeMode = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil Bisnis'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBusinessProfile(user),
          const SizedBox(height: 20),
          _buildSectionTitle('Preferensi'),
          const SizedBox(height: 12),
          _buildPreferences(themeMode),
          const SizedBox(height: 20),
          _buildSectionTitle('AI Preferences'),
          const SizedBox(height: 12),
          _buildAiPreferences(),
          const SizedBox(height: 20),
          _buildSectionTitle('Data & Backup'),
          const SizedBox(height: 12),
          _buildDataSection(),
          const SizedBox(height: 20),
          _buildSectionTitle('Bantuan'),
          const SizedBox(height: 12),
          _buildSupportSection(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildBusinessProfile(UserModel? user) {
    final profile = user?.businessProfile;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.category ?? 'UMKM',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile?.description ??
                'Profil bisnis belum lengkap. Lengkapi profil untuk hasil AI yang lebih relevan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildPreferences(ThemeMode themeMode) {
    return Column(
      children: [
        SwitchListTile(
          value: themeMode == ThemeMode.dark,
          title: const Text('Dark Mode'),
          subtitle: const Text(
            'Mode gelap menjaga tampilan premium di malam hari',
          ),
          activeThumbColor: AppColors.primary,
          onChanged: (value) {
            context.read<ThemeCubit>().updateThemeMode(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
        ListTile(
          title: const Text('Bahasa'),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
          onTap: () => _showOptions(
            title: 'Pilih Bahasa',
            options: ['Indonesia', 'English'],
            selected: _selectedLanguage,
            onSelected: (value) => setState(() => _selectedLanguage = value),
          ),
        ),
        SwitchListTile(
          value: _notificationsEnabled,
          title: const Text('Notifikasi'),
          subtitle: const Text('Terima pengingat dan update penting'),
          activeThumbColor: AppColors.primary,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildAiPreferences() {
    return Column(
      children: [
        _buildSelectionTile(
          title: 'Default Tone',
          value: _selectedTone,
          onTap: () => _showOptions(
            title: 'Pilih Tone AI',
            options: ['Friendly', 'Formal', 'Gen Z', 'Premium'],
            selected: _selectedTone,
            onSelected: (value) => setState(() => _selectedTone = value),
          ),
        ),
        _buildSelectionTile(
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
            onSelected: (value) => setState(() => _selectedMarket = value),
          ),
        ),
        _buildSelectionTile(
          title: 'Platform Default',
          value: _selectedPlatform,
          onTap: () => _showOptions(
            title: 'Pilih Platform',
            options: ['Instagram', 'Shopee', 'Tokopedia', 'WhatsApp'],
            selected: _selectedPlatform,
            onSelected: (value) => setState(() => _selectedPlatform = value),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.download_rounded,
          title: 'Export laporan penjualan',
          subtitle: 'Unduh data transaksi dalam format CSV',
          onTap: () => _showMessage('Export laporan akan siap segera.'),
        ),
        _buildActionTile(
          icon: Icons.cloud_upload_rounded,
          title: 'Backup data',
          subtitle: 'Simpan data produk dan transaksi secara lokal',
          onTap: () => _showMessage('Backup data berhasil disimpan.'),
        ),
        _buildActionTile(
          icon: Icons.sync_rounded,
          title: 'Sinkronisasi Cloud',
          subtitle: 'Jaga data tetap aman dan tersedia di semua perangkat',
          onTap: () => _showMessage('Cloud sync sedang dalam pengembangan.'),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.help_outline_rounded,
          title: 'FAQ',
          subtitle: 'Pertanyaan umum tentang Sellaris',
          onTap: () => _showMessage('Buka FAQ'),
        ),
        _buildActionTile(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Sellaris',
          subtitle: 'Versi aplikasi dan nilai jual utama',
          onTap: () =>
              _showMessage('Sellaris adalah AI Growth Assistant untuk UMKM.'),
        ),
        _buildActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Kebijakan Privasi',
          subtitle: 'Privasi data kamu penting bagi kami',
          onTap: () => _showMessage('Kebijakan Privasi tersedia di website.'),
        ),
      ],
    );
  }

  Widget _buildSelectionTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.surface,
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
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColors.surface,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selected,
                  onChanged: (value) {
                    if (value != null) {
                      onSelected(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }
}
