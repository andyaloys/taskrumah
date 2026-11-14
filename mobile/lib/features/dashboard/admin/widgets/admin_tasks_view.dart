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
                final assignedToName = task['assignedTo'] != null ? task['assignedTo']['name'] as String? : null;

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
                              if (val == 'edit') {
                                _showTaskDialog(context, ref, task: task);
                              } else if (val == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Tugas?'),
                                    content: Text('Apakah Anda yakin ingin menghapus tugas "$title"?'),
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
                                  await repo.deleteTask(id);
                                  ref.invalidate(adminTasksListProvider);
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
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

  void _showTaskDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? task}) {
    final isEdit = task != null;
    final titleController = TextEditingController(text: task?['title'] as String? ?? '');
    final descController = TextEditingController(text: task?['description'] as String? ?? '');
    final pointsController = TextEditingController(text: (task?['points'] as num?)?.toString() ?? '10');
    final targetTimeController = TextEditingController(text: task?['targetTime'] as String? ?? '07:00');
    String selectedEmoji = task?['iconEmoji'] as String? ?? '🧹';
    final repo = ref.read(adminRepositoryProvider);

    final emojiList = ['🧹', '🌱', '📚', '🍽️', '🛏️', '🗑️', '🧺', '🧼', '🍳', '🏃', '🚴', '⏰', '📖', '🐕', '🎒'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                    spacing: 8,
                    children: emojiList.map((e) {
                      final isSelected = selectedEmoji == e;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedEmoji = e),
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nama Tugas *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      labelText: 'Deskripsi / Catatan (Opsional)',
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
                  final points = int.tryParse(pointsController.text) ?? 10;
                  final payload = {
                    'title': title,
                    'description': descController.text.trim(),
                    'points': points,
                    'iconEmoji': selectedEmoji,
                    'targetTime': targetTimeController.text.trim(),
                    'taskType': 0, // Daily
                  };

                  if (isEdit) {
                    await repo.updateTask(task['id'].toString(), payload);
                  } else {
                    await repo.createTask(payload);
                  }
                  ref.invalidate(adminTasksListProvider);
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
