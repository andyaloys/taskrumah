import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../rewards/state/rewards_provider.dart';
import '../state/admin_provider.dart';

final adminRedemptionsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(rewardRepositoryProvider);
  return await repo.getRedemptions();
});

class AdminRewardsView extends ConsumerWidget {
  const AdminRewardsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(adminRewardsListProvider);
    final redemptionsAsync = ref.watch(adminRedemptionsListProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Katalog & Klaim Hadiah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRewardDialog(context, ref),
        backgroundColor: const Color(0xFFF59E0B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Hadiah',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminRewardsListProvider);
          ref.invalidate(adminRedemptionsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PENDING REDEMPTIONS SECTION ---
              redemptionsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (claims) {
                  final pending = claims.where((c) {
                    final status = c['status']?.toString().toLowerCase();
                    return status == 'pending' || status == '0';
                  }).toList();

                  if (pending.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Permintaan Hadiah Menunggu (${pending.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...pending.map((claim) {
                          final id = claim['id']?.toString() ?? '';
                          final title = claim['rewardTitle'] as String? ?? 'Hadiah';
                          final emoji = claim['rewardIconEmoji'] as String? ?? '🎁';
                          final points = (claim['pointsRequired'] as num?)?.toInt() ?? 0;
                          final userName = claim['userName'] as String? ?? 'Anak';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
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
                                      Text(
                                        'Oleh $userName • $points poin',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                                      tooltip: 'Setujui',
                                      onPressed: () async {
                                        await repo.processRedemption(id, 'Approved');
                                        ref.invalidate(adminRedemptionsListProvider);
                                        ref.invalidate(adminRewardsListProvider);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 28),
                                      tooltip: 'Tolak',
                                      onPressed: () async {
                                        await repo.processRedemption(id, 'Rejected');
                                        ref.invalidate(adminRedemptionsListProvider);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              // --- REWARDS CATALOG SECTION ---
              Text(
                'Daftar Hadiah Tersedia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              rewardsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Gagal memuat katalog hadiah: $err'),
                  ),
                ),
                data: (rewards) {
                  if (rewards.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('🎁', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 10),
                            Text(
                              'Belum Ada Hadiah di Katalog',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tekan tombol + Tambah Hadiah untuk membuat reward baru.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rewards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      final id = reward['id']?.toString() ?? '';
                      final title = reward['title'] as String? ?? 'Hadiah';
                      final emoji = reward['iconEmoji'] as String? ?? '🎁';
                      final points = (reward['pointsRequired'] as num?)?.toInt() ?? 0;
                      final desc = reward['description'] as String? ?? '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(emoji, style: const TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '★ $points poin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  _showRewardDialog(context, ref, reward: reward);
                                } else if (val == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Hadiah?'),
                                      content: Text('Yakin ingin menghapus hadiah "$title"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await repo.deleteReward(id);
                                    ref.invalidate(adminRewardsListProvider);
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit Hadiah')),
                                const PopupMenuItem(value: 'delete', child: Text('Hapus Hadiah', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? reward}) {
    final isEdit = reward != null;
    final titleController = TextEditingController(text: reward?['title'] as String? ?? '');
    final descController = TextEditingController(text: reward?['description'] as String? ?? '');
    final pointsController = TextEditingController(text: (reward?['pointsRequired'] as num?)?.toString() ?? '30');
    String selectedEmoji = reward?['iconEmoji'] as String? ?? '🎁';
    final repo = ref.read(adminRepositoryProvider);

    final emojiList = ['💵', '💰', '🎮', '🕹️', '📱', '🍦', '🍕', '🍔', '🍟', '🛹', '🚲', '🧸', '🎁', '⭐', '🍿'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? 'Edit Hadiah' : 'Tambah Hadiah Baru',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Ikon Emoji:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: emojiList.map((e) {
                      final isSelected = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = e),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
                            border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nama Hadiah *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Poin yang Dibutuhkan *',
                      suffixText: 'poin',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Syarat (Opsional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  final points = int.tryParse(pointsController.text) ?? 30;
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'pointsRequired': points,
                    'iconEmoji': selectedEmoji,
                  };

                  if (isEdit) {
                    await repo.updateReward(reward['id'].toString(), payload);
                  } else {
                    await repo.createReward(payload);
                  }
                  ref.invalidate(adminRewardsListProvider);
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }
}
