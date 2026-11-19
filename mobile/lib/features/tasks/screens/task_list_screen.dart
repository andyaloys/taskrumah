import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../models/task_assignment_model.dart';
import '../state/tasks_provider.dart';
import 'submit_task_dialog.dart';
import 'submit_extra_task_dialog.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _selectedMode = 'today'; // 'today', 'yesterday', 'tomorrow', 'custom', 'all'
  String _statusFilter = 'All'; // 'All', 'Pending', 'Submitted', 'Approved', 'Rejected'
  DateTime? _customDate;

  final DateTime _today = DateTime.now();

  bool _canModify(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return false;
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final yesterdayMidnight = DateTime(now.year, now.month, now.day - 1);
      final dueMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return !dueMidnight.isBefore(yesterdayMidnight);
    } catch (_) {
      return false;
    }
  }

  bool _isFuture(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return false;
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final dueMidnight = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return dueMidnight.isAfter(todayMidnight);
    } catch (_) {
      return false;
    }
  }

  void _selectMode(String mode, {DateTime? custom}) {
    setState(() {
      _selectedMode = mode;
      _customDate = custom;
    });

    final notifier = ref.read(tasksNotifierProvider.notifier);
    if (mode == 'today') {
      notifier.changeDatePreset(DatePreset.today);
    } else if (mode == 'yesterday') {
      notifier.changeDatePreset(DatePreset.yesterday);
    } else if (mode == 'tomorrow') {
      notifier.changeDatePreset(DatePreset.tomorrow);
    } else if (mode == 'custom' && custom != null) {
      notifier.changeDate(AppDateUtils.formatYmd(custom));
    } else if (mode == 'all') {
      notifier.showAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final notifier = ref.read(tasksNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Daftar Tugas Saya',
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
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. DATE SELECTOR STRIP (Hari Ini, Kemarin, Besok, Pilih Tanggal, Semua Riwayat)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDatePill(
                    label: 'Hari Ini',
                    isSelected: _selectedMode == 'today',
                    onTap: () => _selectMode('today'),
                  ),
                  const SizedBox(width: 6),
                  _buildDatePill(
                    label: 'Kemarin',
                    isSelected: _selectedMode == 'yesterday',
                    onTap: () => _selectMode('yesterday'),
                  ),
                  const SizedBox(width: 6),
                  _buildDatePill(
                    label: 'Besok',
                    isSelected: _selectedMode == 'tomorrow',
                    onTap: () => _selectMode('tomorrow'),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _customDate ?? _today,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        _selectMode('custom', custom: picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _selectedMode == 'custom' ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedMode == 'custom' ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 13,
                            color: _selectedMode == 'custom' ? Colors.white : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedMode == 'custom' && _customDate != null
                                ? DateFormat('dd MMM').format(_customDate!)
                                : 'Pilih Tanggal',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _selectedMode == 'custom' ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildDatePill(
                    label: 'Semua Riwayat',
                    isSelected: _selectedMode == 'all',
                    onTap: () => _selectMode('all'),
                  ),
                ],
              ),
            ),
          ),

          // 2. STATUS FILTER CHIPS (Only when 'all' or always visible for filtering)
          if (_selectedMode == 'all')
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('All', 'Semua Status'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Pending', 'Menunggu'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Submitted', 'Terkirim'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Approved', 'Disetujui'),
                    const SizedBox(width: 6),
                    _buildStatusChip('Rejected', 'Ditolak'),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // 3. LAPOR TUGAS TAMBAHAN BANNER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: InkWell(
              onTap: () => SubmitExtraTaskDialog.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🌟', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+ Lapor Tugas Tambahan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Tugas tambahan di luar jadwal rutin (kapan saja)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                  ],
                ),
              ),
            ),
          ),

          // 4. TASK LIST BODY
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => notifier.refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allTasks) {
                // Apply status filter if set
                final tasks = allTasks.where((t) {
                  if (_statusFilter == 'All') return true;
                  if (_statusFilter == 'Pending') return t.isPending;
                  if (_statusFilter == 'Submitted') return t.isSubmitted;
                  if (_statusFilter == 'Approved') return t.isApproved;
                  if (_statusFilter == 'Rejected') return t.isRejected;
                  return true;
                }).toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📋', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak Ada Tugas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedMode == 'all'
                                ? 'Tidak ada tugas yang sesuai dengan filter.'
                                : 'Tidak ada tugas yang dijadwalkan pada hari ini.',
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

                return RefreshIndicator(
                  color: const Color(0xFF6366F1),
                  onRefresh: () => notifier.refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                    itemCount: tasks.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
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

  Widget _buildDatePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskAssignmentModel item) {
    final bool canModify = _canModify(item.dueDate);
    final bool isFuture = _isFuture(item.dueDate);

    String? fullPhotoUrl;
    if (item.proofPhotoUrl != null && item.proofPhotoUrl!.isNotEmpty) {
      if (item.proofPhotoUrl!.startsWith('http')) {
        fullPhotoUrl = item.proofPhotoUrl;
      } else {
        fullPhotoUrl = '${ApiConstants.baseHost}/${item.proofPhotoUrl!.replaceAll('\\', '/')}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isApproved
              ? const Color(0xFFA7F3D0)
              : item.isRejected
                  ? const Color(0xFFFECDD3)
                  : const Color(0xFFE2E8F0),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '+${item.points} poin',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                        if (item.targetTime != null && item.targetTime!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: Text(
                              '⏰ ${item.targetTime}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        if (_selectedMode == 'all' && item.dueDate.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppDateUtils.formatDisplay(item.dueDate),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(item, isFuture),
            ],
          ),

          // Rejection reason note if rejected
          if (item.isRejected && item.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFE11D48), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan penolakan: ${item.rejectionReason}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFBE123C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Duplicate warning banner if flagged
          if (item.isDuplicateProof) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Text('âš ï¸', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.duplicateWarning ?? 'Terindikasi kemiripan foto dengan tugas sebelumnya',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Submission note if submitted
          if (item.submissionNote != null && item.submissionNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Catatanmu: "${item.submissionNote}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],

          // Proof photo preview if submitted
          if (fullPhotoUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 100,
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: Image.network(
                  fullPhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Foto bukti terunggah', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ),
                ),
              ),
            ),
          ],

          // Action Button
          const SizedBox(height: 12),
          if (isFuture) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'Terjadwal untuk masa depan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if (item.isApproved) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Color(0xFF047857)),
                  SizedBox(width: 6),
                  Text(
                    'Tugas Disetujui! Poin telah didapatkan 🎉',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
          ] else if (item.isSubmitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 14, color: Color(0xFF0369A1)),
                  SizedBox(width: 6),
                  Text(
                    'Menunggu Review Orang Tua ⏳',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
          ] else if (!canModify) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF94A3B8)),
                  SizedBox(width: 6),
                  Text(
                    'Terkunci (> 1 hari yang lalu)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => SubmitTaskDialog.show(context, item),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: Text(
                  item.isRejected ? 'Perbaiki & Kirim Ulang Bukti' : 'Kirim Bukti Tugas',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isRejected ? const Color(0xFFE11D48) : const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskAssignmentModel item, bool isFuture) {
    if (isFuture) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Text(
          'Terjadwal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4338CA),
          ),
        ),
      );
    }

    if (item.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Text(
          'Disetujui',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF047857),
          ),
        ),
      );
    }

    if (item.isSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Text(
          'Terkirim',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0369A1),
          ),
        ),
      );
    }

    if (item.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Text(
          'Ditolak',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFBE123C),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Text(
        'Menunggu',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFB45309),
        ),
      ),
    );
  }
}
