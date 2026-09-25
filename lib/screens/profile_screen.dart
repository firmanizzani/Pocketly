import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_logo.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onGoHome, required this.onGoBudget});

  final VoidCallback onGoHome;
  final VoidCallback onGoBudget;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _header(onGoHome, onGoBudget),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _profileCard(context, state, user?.initials ?? 'M', user?.name ?? '-',
                    user?.email ?? '-'),
                const SizedBox(height: 18),
                _sectionTitle('AKUN & KEAMANAN'),
                _card([
                  _tile(
                    icon: Icons.person_outline,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama dan email akunmu',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _sectionTitle('PREFERENSI & NOTIFIKASI'),
                _card([
                  _tile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Pengingat Budget',
                    subtitle: 'Notifikasi harian & peringatan batas 80%',
                    trailing: Switch(
                      value: state.budgetReminder,
                      onChanged: (_) => context.read<AppState>().toggleBudgetReminder(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primaryContainer,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.secondaryFixed,
                    ),
                  ),
                  const Divider(height: 1, indent: 64),
                  _tile(
                    icon: Icons.payments_outlined,
                    title: 'Mata Uang & Format',
                    subtitle: 'Format angka dan simbol saldo',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('IDR (Rp)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                _sectionTitle('BANTUAN & INFORMASI'),
                _card([
                  _tile(
                    icon: Icons.info_outline,
                    title: 'Tentang Pocketly',
                    subtitle: 'Aplikasi pengelola keuangan mahasiswa',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('v1.0.0',
                            style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Keluar dari Akun',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorContainer,
                      foregroundColor: AppColors.onErrorContainer,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pocketly untuk Generasi Mandiri Finansial',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(VoidCallback onGoHome, VoidCallback onGoBudget) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const AppLogo(size: 36, radius: 10),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Pocketly',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1.2)),
              Text('Profil Saya',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onGoBudget,
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    await state.setAvatarPath(picked.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil diperbarui!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _profileCard(
      BuildContext context, AppState state, String initials, String name, String email) {
    final avatarPath = state.avatarPath;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: cardDecoration(radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryFixed.withValues(alpha: 0.35), blurRadius: 30)
                ],
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  shape: BoxShape.circle),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryFixed, AppColors.primaryContainer],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primaryFixed.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarPath != null && File(avatarPath).existsSync()
                        ? Image.file(
                            File(avatarPath),
                            fit: BoxFit.cover,
                            width: 104,
                            height: 104,
                          )
                        : Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _pickAvatar(context, state),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              const SizedBox(height: 4),
              Text(email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.secondary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 15, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Akun Terverifikasi',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: cardDecoration(radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  const BoxDecoration(color: AppColors.surfaceContainer, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Pocketly?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppState>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
