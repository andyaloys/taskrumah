import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_upload_helper.dart';
import '../../../core/widgets/user_avatar_widget.dart';
import '../../auth/state/auth_provider.dart';

class ChildProfileView extends ConsumerWidget {
  const ChildProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  UserAvatarWidget(
                    avatarUrl: user?.fullAvatarUrl,
                    name: user?.name,
                    userId: user?.id,
                    size: 80,
                    borderRadius: 22,
                    canEdit: true,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      AvatarUploadHelper.pickAndUpload(
                        context,
                        ref,
                        targetUserId: user?.id,
                        targetUserName: user?.name,
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF6366F1)),
                    label: Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Anak Hebat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 14)),
                            Text(
                              '${user?.totalPoints ?? 0} Poin',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 14)),
                            Text(
                              '${user?.currentStreak ?? 0} Hari Streak',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  _ProfileRow(label: 'Aplikasi', value: 'FamilyTask Mobile'),
                  Divider(height: 16),
                  _ProfileRow(label: 'Versi', value: 'v1.1.0'),
                  Divider(height: 16),
                  _ProfileRow(label: 'Peran', value: 'Anak Hebat 🧒'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  'Keluar (Logout)',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
                onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
