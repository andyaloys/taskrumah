import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final authState = ref.watch(authNotifierProvider);
    final userPoints = authState.user?.totalPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Toko Hadiah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Points Summary Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Catalog List
          Expanded(
            child: rewardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (rewards) {
                if (rewards.isEmpty) {
                  return const Center(child: Text('Belum ada katalog hadiah.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rewards.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = rewards[index];
                    final canAfford = userPoints >= item.pointsRequired;
                    final progress = (userPoints / (item.pointsRequired > 0 ? item.pointsRequired : 1)).clamp(0.0, 1.0);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(item.iconEmoji ?? '🎁', style: const TextStyle(fontSize: 26)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.description != null && item.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.pointsRequired} Poin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                canAfford ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Claim Button
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: canAfford ? () => _confirmClaim(context, ref, item) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFE2E8F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                canAfford ? 'Tukarkan Hadiah 🎁' : 'Poin Belum Cukup ($userPoints / ${item.pointsRequired})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
