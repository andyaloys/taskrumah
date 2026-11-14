import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../features/dashboard/admin/state/admin_provider.dart';
import '../constants/api_constants.dart';

class AvatarUploadHelper {
  static Future<void> pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    String? targetUserId,
    String? targetUserName,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final userId = targetUserId ?? currentUser?.id;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Pengguna tidak ditemukan')),
      );
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubah Foto Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (targetUserName != null)
                      Text(
                        'Untuk $targetUserName',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF6366F1), size: 22),
                ),
                title: Text(
                  'Ambil dari Kamera',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Gunakan kamera HP langsung',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF10B981), size: 22),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Pilih foto dari penyimpanan galeri',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(width: 16),
              Text(
                'Mengupload foto profil...',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final client = ref.read(apiClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path),
      });

      final response = await client.dio.post(
        '${ApiConstants.users}/$userId/avatar',
        data: formData,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      final data = response.data as Map<String, dynamic>;
      final newAvatarUrl = data['avatarUrl'] as String?;

      if (newAvatarUrl != null) {
        // If this was the current logged-in user, update current auth state
        if (currentUser?.id == userId) {
          await ref.read(authNotifierProvider.notifier).updateAvatar(newAvatarUrl);
        }
      }

      // Refresh any user/dashboard lists
      ref.invalidate(adminUsersListProvider);
      ref.invalidate(adminDashboardNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
