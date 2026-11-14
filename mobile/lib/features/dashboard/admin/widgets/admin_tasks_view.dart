import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/admin_provider.dart';

class AdminTasksView extends ConsumerStatefulWidget {
  const AdminTasksView({super.key});

  @override
  ConsumerState<AdminTasksView> createState() => _AdminTasksViewState();
}

class _AdminTasksViewState extends ConsumerState<AdminTasksView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Kelola Tugas & Ibadah',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Daftar Tugas'),
            Tab(text: 'Pengaturan Ibadah'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _AdminTaskListTab(),
          const _AdminWorshipSettingTab(),
        ],
      ),
    );
  }
}

class _AdminTaskListTab extends ConsumerWidget {
  const _AdminTaskListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(adminTasksListProvider);
    final repo = ref.read(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context, ref),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Tugas',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminTasksListProvider),
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Gagal memuat tugas: $err'),
            ),
          ),
          data: (tasks) {
            if (tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Tugas Rumah',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tekan tombol + Tambah Tugas di bawah untuk membuat tugas pertama.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = tasks[index];
                final id = task['id']?.toString() ?? '';
                final title = task['title'] as String? ?? 'Tugas';
                final emoji = task['iconEmoji'] as String? ?? '📋';
                final points = (task['points'] as num?)?.toInt() ?? 0;
                final targetTime = task['targetTime'] as String?;
                final isActive = task['isActive'] == true;
                final taskType = (task['taskType'] as num?)?.toInt() ?? 0;
                final daysOfWeek = task['daysOfWeek'] as String?;
                final assignedToName = task['assignedTo'] != null ? task['assignedTo']['name'] as String? : null;

                String scheduleLabel = 'Rutin Setiap Hari';
                if (taskType == 1) {
                  scheduleLabel = 'Hari Tertentu';
                  if (daysOfWeek != null && daysOfWeek.isNotEmpty) {
                    final dayMap = {'1': 'Sen', '2': 'Sel', '3': 'Rab', '4': 'Kam', '5': 'Jum', '6': 'Sab', '7': 'Min'};
                    final dayNames = daysOfWeek.split(',').map((d) => dayMap[d.trim()] ?? d).join(', ');
                    scheduleLabel = 'Hari: $dayNames';
                  }
                } else if (taskType == 2) {
                  scheduleLabel = '🌟 Tugas Tambahan';
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
                                color: isActive ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                decoration: isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: taskType == 2 ? const Color(0xFFFAF5FF) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: taskType == 2 ? const Color(0xFFE9D5FF) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    scheduleLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: taskType == 2 ? const Color(0xFF7E22CE) : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+$points poin',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                if (targetTime != null && targetTime.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      '⏰ $targetTime',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    assignedToName ?? 'Semua Anak',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: const Color(0xFF6366F1),
                            onChanged: (val) async {
                              await repo.updateTask(id, {'isActive': val});
                              ref.invalidate(adminTasksListProvider);
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                            onSelected: (val) async {
                              if (val == 'assign') {
                                _showAssignDialog(context, ref, task);
                              } else if (val == 'edit') {
                                _showTaskDialog(context, ref, task: task);
                              } else if (val == 'delete') {
                                final usage = await repo.getTaskUsage(id);
                                final bool hasHistory = usage['hasHistory'] == true;
                                final int completedCount = (usage['completedAssignments'] as num?)?.toInt() ?? 0;
                                final int totalCount = (usage['totalAssignments'] as num?)?.toInt() ?? 0;

                                if (!context.mounted) return;

                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: Row(
                                      children: [
                                        Icon(
                                          hasHistory ? Icons.warning_amber_rounded : Icons.delete_outline,
                                          color: hasHistory ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            hasHistory ? 'Tugas Pernah Digunakan' : 'Hapus Tugas?',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (hasHistory) ...[
                                            Text(
                                              'Tugas "$title" sudah memiliki riwayat penugasan:',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155)),
                                            ),
                                            const SizedBox(height: 6),
                                            Text('• Pernah selesai: $completedCount kali', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                            Text('• Total penugasan: $totalCount kali', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF475569))),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFFBBF7D0)),
                                              ),
                                              child: Text(
                                                '✅ Poin anak yang sudah didapat TETAP AMAN & TIDAK BERKURANG.',
                                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                              ),
                                              child: Text(
                                                '💡 Tips: Anda juga cukup menonaktifkan saklar jika hanya ingin menghentikan tugas tanpa menghapus riwayat.',
                                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF1D4ED8)),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Apakah Anda tetap yakin ingin menghapus tugas ini secara permanen?',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                                            ),
                                          ] else ...[
                                            Text(
                                              'Tugas "$title" belum pernah dikerjakan oleh anak.\n\nApakah Anda yakin ingin menghapus tugas ini?',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF334155)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(hasHistory ? 'Tetap Hapus' : 'Hapus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await repo.deleteTask(id);
                                    ref.invalidate(adminTasksListProvider);
                                    ref.invalidate(adminDashboardNotifierProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Tugas "$title" berhasil dihapus'),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal menghapus tugas: $e'),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'assign', child: Text('Tugaskan Sekarang 📅')),
                              const PopupMenuItem(value: 'edit', child: Text('Edit Tugas')),
                              const PopupMenuItem(value: 'delete', child: Text('Hapus Tugas', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
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

  void _showAssignDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> task) {
    final usersAsync = ref.read(adminUsersListProvider).value ?? [];
    final children = usersAsync.where((u) {
      final role = u['role']?.toString().toLowerCase();
      return role == 'child' || role == '1';
    }).toList();

    String? selectedChildId = task['assignedToId']?.toString();
    DateTime selectedDate = DateTime.now();
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Text('📅 ', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: Text(
                    'Tugaskan Sekarang',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tugaskan "${task['title']}" ke anak pada tanggal yang dipilih:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  Text('Pilih Anak:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedChildId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua Anak (Umum)'),
                          ),
                          ...children.map((c) => DropdownMenuItem<String?>(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? 'Anak'),
                          )),
                        ],
                        onChanged: (val) => setDialogState(() => selectedChildId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Tanggal Pelaksanaan:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isAssigning
                    ? null
                    : () async {
                        setDialogState(() => isAssigning = true);
                        try {
                          final repo = ref.read(adminRepositoryProvider);
                          final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                          await repo.assignTask(
                            task['id'].toString(),
                            assignedToId: selectedChildId,
                            dueDate: dateStr,
                          );
                          ref.invalidate(adminDashboardNotifierProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tugas "${task['title']}" berhasil ditugaskan! 🎉'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isAssigning = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isAssigning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Tugaskan Sekarang'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTaskDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? task}) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?['title'] as String? ?? '');
    final descController = TextEditingController(text: task?['description'] as String? ?? '');
    final pointsController = TextEditingController(text: (task?['points'] as num?)?.toString() ?? '10');
    final targetTimeController = TextEditingController(text: task?['targetTime'] as String? ?? '07:00');
    final customEmojiController = TextEditingController();
    String selectedEmoji = task?['iconEmoji'] as String? ?? '🧹';
    int taskType = (task?['taskType'] as num?)?.toInt() ?? 0; // 0: Daily, 1: SpecificDays, 2: OneTime
    String? assignedToId = task?['assignedToId']?.toString();

    final Set<String> selectedDays = {};
    if (task?['daysOfWeek'] != null && (task!['daysOfWeek'] as String).isNotEmpty) {
      selectedDays.addAll((task['daysOfWeek'] as String).split(',').map((s) => s.trim()));
    } else {
      selectedDays.addAll(['1', '2', '3', '4', '5']); // Default Mon-Fri
    }

    final daysList = [
      {'id': '1', 'label': 'Senin'},
      {'id': '2', 'label': 'Selasa'},
      {'id': '3', 'label': 'Rabu'},
      {'id': '4', 'label': 'Kamis'},
      {'id': '5', 'label': 'Jumat'},
      {'id': '6', 'label': 'Sabtu'},
      {'id': '7', 'label': 'Minggu'},
    ];

    final emojiList = [
      '🧹', '🌱', '📚', '🍽️', '🛏️', '🗑️', '🧺', '🧼', '🍳', '🧴',
      '🏃', '🚴', '⚽', '🏀', '🏸', '🧘', '🏊', '⏰', '🌅', '🛌',
      '🚪', '🔐', '🔑', '🕌', '📖', '🤲', '🎒', '✏️', '💻', '✅',
    ];

    final usersAsync = ref.read(adminUsersListProvider).value ?? [];
    final children = usersAsync.where((u) {
      final role = u['role']?.toString().toLowerCase();
      return role == 'child' || role == '1';
    }).toList();

    final repo = ref.read(adminRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              isEdit ? 'Edit Tugas' : 'Tambah Tugas Baru',
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
                    spacing: 6,
                    runSpacing: 6,
                    children: emojiList.map((e) {
                      final isSelected = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          selectedEmoji = e;
                          customEmojiController.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                            border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customEmojiController,
                    decoration: InputDecoration(
                      hintText: 'Atau ketik emoji khusus di sini...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      if (val.trim().isNotEmpty) {
                        setDialogState(() => selectedEmoji = val.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nama Tugas *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Jadwal Tugas (taskType)
                  Text('Jadwal Tugas:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: taskType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Rutin Setiap Hari')),
                          DropdownMenuItem(value: 1, child: Text('Hari Tertentu')),
                          DropdownMenuItem(value: 2, child: Text('🌟 Tugas Tambahan (Kapan Saja)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => taskType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Specific Days selector
                  if (taskType == 1) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pilih Hari Pelaksanaan:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: daysList.map((d) {
                              final dayId = d['id']!;
                              final isChecked = selectedDays.contains(dayId);
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    if (isChecked) {
                                      selectedDays.remove(dayId);
                                    } else {
                                      selectedDays.add(dayId);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isChecked ? const Color(0xFF6366F1) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isChecked ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    '${d['label']} ${isChecked ? '✓' : ''}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                                      color: isChecked ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (selectedDays.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('Pilih minimal 1 hari pelaksanaan!', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (taskType == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Text(
                        '🌟 Tugas Tambahan: Tidak muncul otomatis setiap hari. Anak dapat melaporkan tugas ini secara mandiri kapan saja.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6B21A8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Penugasan Anak
                  Text('Penugasan:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: assignedToId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Semua Anak (Umum)'),
                          ),
                          ...children.map((c) => DropdownMenuItem<String?>(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? 'Anak'),
                          )),
                        ],
                        onChanged: (val) => setDialogState(() => assignedToId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Poin *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: targetTimeController,
                          decoration: InputDecoration(
                            labelText: 'Batas Jam (HH:mm)',
                            hintText: '07:00',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi / Petunjuk (Opsional)',
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
                  if (taskType == 1 && selectedDays.isEmpty) return;

                  final points = int.tryParse(pointsController.text) ?? 10;
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'points': points,
                    'iconEmoji': selectedEmoji,
                    'targetTime': targetTimeController.text.trim(),
                    'taskType': taskType,
                    'daysOfWeek': taskType == 1 ? (selectedDays.toList()..sort()).join(',') : null,
                    'assignedToId': (assignedToId != null && assignedToId!.isNotEmpty) ? assignedToId : null,
                  };

                  if (isEdit) {
                    await repo.updateTask(task['id'].toString(), payload);
                  } else {
                    await repo.createTask(payload);
                  }
                  ref.invalidate(adminTasksListProvider);
                  ref.invalidate(adminDashboardNotifierProvider);
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isEdit ? 'Simpan' : 'Buat Tugas'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminWorshipSettingTab extends ConsumerStatefulWidget {
  const _AdminWorshipSettingTab();

  @override
  ConsumerState<_AdminWorshipSettingTab> createState() => _AdminWorshipSettingTabState();
}

class _AdminWorshipSettingTabState extends ConsumerState<_AdminWorshipSettingTab> {
  final _soloController = TextEditingController();
  final _mosqueController = TextEditingController();
  final _quranController = TextEditingController();
  final _reminderController = TextEditingController();
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    final settingAsync = ref.watch(adminWorshipSettingProvider);
    final repo = ref.read(adminRepositoryProvider);

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      error: (err, _) => Center(child: Text('Gagal memuat pengaturan: $err')),
      data: (setting) {
        if (!_isLoaded) {
          _soloController.text = (setting['soloPoints'] ?? 3).toString();
          _mosqueController.text = (setting['mosquePoints'] ?? 5).toString();
          _quranController.text = (setting['quranPoints'] ?? 5).toString();
          _reminderController.text = (setting['reminderMinutesBeforeEnd'] ?? 30).toString();
          _isLoaded = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poin Sholat 5 Waktu',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur poin yang didapatkan anak saat menunaikan sholat fardhu.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _soloController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Poin Sholat Sendiri / di Rumah / Sekolah',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
                        suffixText: 'poin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mosqueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Poin Sholat Berjamaah di Masjid',
                        prefixIcon: const Icon(Icons.mosque_outlined, color: Color(0xFF10B981)),
                        suffixText: 'poin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poin Mengaji & Tilawah',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _quranController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Poin Baca Al-Quran / Iqra',
                        prefixIcon: const Icon(Icons.menu_book_outlined, color: Color(0xFFF59E0B)),
                        suffixText: 'poin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Pengingat Sholat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _reminderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pengingat Sebelum Batas Waktu Habis',
                        prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFFEF4444)),
                        suffixText: 'menit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            await repo.updateWorshipSetting({
                              'soloPoints': int.tryParse(_soloController.text) ?? 3,
                              'mosquePoints': int.tryParse(_mosqueController.text) ?? 5,
                              'quranPoints': int.tryParse(_quranController.text) ?? 5,
                              'reminderMinutesBeforeEnd': int.tryParse(_reminderController.text) ?? 30,
                            });
                            ref.invalidate(adminWorshipSettingProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pengaturan ibadah berhasil disimpan!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menyimpan: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Pengaturan Ibadah',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
