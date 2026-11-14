import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rewards/state/rewards_provider.dart';

final adminRedemptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(rewardRepositoryProvider);
  return await repo.getRedemptions();
});

class AdminRewardsView extends ConsumerWidget {
  const AdminRewardsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redemptionsAsync = ref.watch(adminRedemptionsProvider);
    final repo = ref.read(rewardRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Persetujuan Klaim Hadiah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminRedemptionsProvider);
        },
        child: redemptionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Gagal memuat klaim hadiah: $err'),
            ),
          ),
          data: (claims) {
            if (claims.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Klaim Hadiah',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Permintaan tukar poin dari anak akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final c = claims[index];
                final id = c['id']?.toString() ?? '';
                final title = c['rewardTitle'] as String? ?? 'Hadiah';
                final emoji = c['rewardIconEmoji'] as String? ?? '🎁';
                final points = (c['pointsRequired'] as num?)?.toInt() ?? 0;
                final userName = c['userName'] as String? ?? 'Anak';
                final status = c['status']?.toString() ?? 'Pending';
                final isPending = status == 'Pending';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Diajukan oleh $userName • $points Poin',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? const Color(0xFFFEF3C7)
                                  : (status == 'Approved'
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPending ? 'Menunggu' : (status == 'Approved' ? 'Disetujui' : 'Ditolak'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPending
                                    ? const Color(0xFFD97706)
                                    : (status == 'Approved'
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF991B1B)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  await repo.processRedemption(id, 'Rejected', notes: 'Poin dikembalikan');
                                  ref.invalidate(adminRedemptionsProvider);
                                },
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  await repo.processRedemption(id, 'Approved');
                                  ref.invalidate(adminRedemptionsProvider);
                                },
                                child: const Text('Setujui 🎁'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
