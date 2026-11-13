import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/task_assignment_model.dart';
import '../state/tasks_provider.dart';
import 'submit_task_dialog.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final notifier = ref.read(tasksNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Daftar Tugas Harian',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Kemarin, Hari Ini, Besok)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildDateTab(
                  label: 'Kemarin',
                  selected: notifier.currentPreset == DatePreset.yesterday,
                  onTap: () => notifier.changeDatePreset(DatePreset.yesterday),
                ),
                const SizedBox(width: 8),
                _buildDateTab(
                  label: 'Hari Ini',
                  selected: notifier.currentPreset == DatePreset.today,
                  onTap: () => notifier.changeDatePreset(DatePreset.today),
                ),
                const SizedBox(width: 8),
                _buildDateTab(
                  label: 'Besok',
                  selected: notifier.currentPreset == DatePreset.tomorrow,
                  onTap: () => notifier.changeDatePreset(DatePreset.tomorrow),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Task List Body
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat tugas',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => notifier.refresh(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.celebration_rounded, size: 56, color: Color(0xFFF59E0B)),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak Ada Tugas!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Belum ada tugas yang dijadwalkan untuk hari ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => notifier.refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      return _buildTaskCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskAssignmentModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isApproved
              ? const Color(0xFFD1FAE5)
              : item.isRejected
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(item.iconEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
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
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${item.points} Poin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(item),
            ],
          ),

          // Rejection reason note if rejected
          if (item.isRejected && item.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan: ${item.rejectionReason}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Button (Submit Proof if pending or rejected)
          if (item.isPending || item.isRejected) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => SubmitTaskDialog.show(context, item),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(
                  item.isRejected ? 'Kirim Ulang Bukti' : 'Kirim Bukti Tugas',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskAssignmentModel item) {
    if (item.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
            const SizedBox(width: 4),
            Text(
              'Disetujui',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ),
      );
    }

    if (item.isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              'Menunggu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }

    if (item.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel, size: 12, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text(
              'Perlu Diulang',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Belum Selesai',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}
