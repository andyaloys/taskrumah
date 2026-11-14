import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_provider.dart';
import '../models/reward_model.dart';
import '../state/rewards_provider.dart';

class RewardShopScreen extends ConsumerWidget {
  const RewardShopScreen({super.key});

  void _confirmClaim(BuildContext context, WidgetRef ref, RewardModel reward) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Klaim Hadiah? 🎁',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            'Apakah kamu yakin ingin menukarkan ${reward.pointsRequired} poin untuk "${reward.title}"?',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(rewardsNotifierProvider.notifier).claim(reward.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text(
                          'Permintaan klaim berhasil diajukan ke orang tua! 🎉',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.danger,
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: GoogleFonts.plusJakartaSans(color: Colors.white),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Ya, Tukarkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsNotifierProvider);
    final redemptionsAsync = ref.watch(childRedemptionsListProvider);
    final authState = ref.watch(authNotifierProvider);
    final userPoints = authState.user?.totalPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Katalog & Hadiah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.read(rewardsNotifierProvider.notifier).refresh();
              ref.invalidate(childRedemptionsListProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(rewardsNotifierProvider.notifier).refresh();
          ref.invalidate(childRedemptionsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Points Balance Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Poin Kamu Saat Ini',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          '$userPoints Poin Tersedia',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Section Title: Katalog Hadiah
              Text(
                'KATALOG HADIAH TERSEDIA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Rewards List
              rewardsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Gagal memuat hadiah: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada hadiah yang tersedia di katalog.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: rewards.map((item) {
                      final canAfford = userPoints >= item.pointsRequired;
                      final progress = (userPoints / (item.pointsRequired > 0 ? item.pointsRequired : 1)).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(item.iconEmoji ?? '🎁', style: const TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (item.description != null && item.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.description!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.pointsRequired} Poin',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  canAfford ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Claim Button
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: canAfford ? () => _confirmClaim(context, ref, item) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF59E0B),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                                  disabledForegroundColor: const Color(0xFF94A3B8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  canAfford ? 'Tukarkan Hadiah 🎁' : 'Poin Belum Cukup ($userPoints / ${item.pointsRequired})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Section Title: Riwayat Pengajuan Hadiah
              Text(
                'RIWAYAT PENGAJUAN HADIAH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              redemptionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text('Gagal memuat riwayat: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
                ),
                data: (redemptions) {
                  if (redemptions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat penukaran hadiah.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: redemptions.map((r) {
                      final title = r['rewardTitle'] as String? ?? 'Hadiah';
                      final emoji = r['rewardIconEmoji'] as String? ?? '🎁';
                      final points = (r['pointsRequired'] as num?)?.toInt() ?? 0;
                      final rawStatus = r['status']?.toString().toLowerCase();

                      String statusLabel = 'Menunggu';
                      Color statusBg = const Color(0xFFFEF3C7);
                      Color statusBorder = const Color(0xFFFDE68A);
                      Color statusColor = const Color(0xFFB45309);

                      if (rawStatus == 'approved' || rawStatus == '1') {
                        statusLabel = 'Disetujui ✓';
                        statusBg = const Color(0xFFECFDF5);
                        statusBorder = const Color(0xFFA7F3D0);
                        statusColor = const Color(0xFF047857);
                      } else if (rawStatus == 'rejected' || rawStatus == '2') {
                        statusLabel = 'Ditolak';
                        statusBg = const Color(0xFFFFF1F2);
                        statusBorder = const Color(0xFFFECDD3);
                        statusColor = const Color(0xFFBE123C);
                      }

                      String dateFormatted = '';
                      if (r['requestedAt'] != null) {
                        try {
                          final dt = DateTime.parse(r['requestedAt'].toString());
                          dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                        } catch (_) {
                          dateFormatted = r['requestedAt'].toString();
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              alignment: Alignment.center,
                              child: Text(emoji, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$points poin • $dateFormatted',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusBorder),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
