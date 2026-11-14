import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_provider.dart';
import '../../tasks/models/task_assignment_model.dart';
import '../../tasks/screens/submit_extra_task_dialog.dart';
import '../../tasks/screens/submit_task_dialog.dart';
import '../../tasks/screens/task_list_screen.dart';
import '../../tasks/state/tasks_provider.dart';
import '../../worship/models/worship_model.dart';
import '../../worship/screens/worship_screen.dart';
import '../../worship/state/worship_provider.dart';
import '../../rewards/screens/reward_shop_screen.dart';
import '../../profile/screens/child_profile_view.dart';

class ChildDashboardScreen extends ConsumerStatefulWidget {
  const ChildDashboardScreen({super.key});

  @override
  ConsumerState<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends ConsumerState<ChildDashboardScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _ChildHomeTab(onSwitchTab: _switchTab),
      const TaskListScreen(),
      const WorshipScreen(),
      const RewardShopScreen(),
      const ChildProfileView(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: const Color(0xFFEEF2FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6366F1)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rtl_rounded, color: Color(0xFF6366F1)),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque_outlined),
            selectedIcon: Icon(Icons.mosque_rounded, color: Color(0xFF10B981)),
            label: 'Ibadah',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard_rounded, color: Color(0xFFF59E0B)),
            label: 'Hadiah',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6366F1)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ChildHomeTab extends ConsumerWidget {
  final ValueChanged<int> onSwitchTab;
  const _ChildHomeTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final worshipAsync = ref.watch(worshipNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'FamilyTask',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.read(tasksNotifierProvider.notifier).refresh();
              ref.read(worshipNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tasksNotifierProvider.notifier).refresh();
          await ref.read(worshipNotifierProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Gamification Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hai, ${user?.name ?? 'Anak Hebat'}! 👋',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Semangat selesaikan misi hari ini!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            (user?.name.isNotEmpty == true) ? user!.name[0] : 'A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Points & Streak stats
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFFDE047), size: 28),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user?.totalPoints ?? 0}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Total Poin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Color(0xFFFB923C), size: 28),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user?.currentStreak ?? 0} Hari',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Rekor Streak',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lapor Tugas Tambahan Quick Action Banner
              InkWell(
                onTap: () => SubmitExtraTaskDialog.show(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🌟', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selesai Tugas Tambahan?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lapor cuci motor, ngaji ekstra, dll untuk poin bonus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lapor ➜',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9333EA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sholat 5 Waktu Hari Ini Card
              worshipAsync.maybeWhen(
                data: (record) {
                  if (record == null) return const SizedBox.shrink();
                  return _buildWorshipQuickCard(context, record);
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Quick Menu Grid
              Text(
                'Menu Utama',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickCard(
                    title: 'Tugas Hari Ini',
                    subtitle: 'Misi & Poin',
                    icon: Icons.checklist_rtl_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () => onSwitchTab(1),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickCard(
                    title: 'Ibadah Sholat',
                    subtitle: '5 Waktu & Doa',
                    icon: Icons.mosque_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onSwitchTab(2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickCard(
                    title: 'Toko Hadiah',
                    subtitle: 'Tukar Poinmu',
                    icon: Icons.card_giftcard_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => onSwitchTab(3),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickCard(
                    title: 'Profil Saya',
                    subtitle: 'Foto & Akun',
                    icon: Icons.person_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: () => onSwitchTab(4),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tugas Hari Ini Preview List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Misi Tugas Hari Ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSwitchTab(1),
                    child: Text(
                      'Lihat Semua ➜',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              tasksAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Gagal memuat tugas: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(child: Text('Tidak ada tugas untuk hari ini.')),
                    );
                  }

                  return Column(
                    children: tasks.take(4).map((t) => _buildTaskPreviewItem(context, t)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorshipQuickCard(BuildContext context, DailyWorshipModel record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🕌 ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Sholat 5 Waktu Hari Ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => onSwitchTab(2),
                child: Text(
                  'Catat ➜',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSholatPill('Subuh', record.subuh),
              _buildSholatPill('Dzuhur', record.dzuhur),
              _buildSholatPill('Ashar', record.ashar),
              _buildSholatPill('Maghrib', record.maghrib),
              _buildSholatPill('Isya', record.isya),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSholatPill(String name, int status) {
    final bool done = status > 0;
    final bool mosque = status == 2;

    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: done ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: done ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            done ? (mosque ? '🕌' : '✓') : '○',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: done ? const Color(0xFF065F46) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskPreviewItem(BuildContext context, TaskAssignmentModel task) {
    Color statusColor;
    String statusLabel;

    if (task.isApproved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Disetujui';
    } else if (task.isSubmitted) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Menunggu';
    } else if (task.isRejected) {
      statusColor = Colors.red;
      statusLabel = 'Ditolak';
    } else {
      statusColor = const Color(0xFF6366F1);
      statusLabel = 'Tersedia';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(task.iconEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '+${task.points} Poin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    if (task.targetTime != null && task.targetTime!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '⏰ ${task.targetTime}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (task.isPending)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => SubmitTaskDialog.show(context, task),
              child: const Text('Kerjakan', style: TextStyle(fontSize: 12)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
