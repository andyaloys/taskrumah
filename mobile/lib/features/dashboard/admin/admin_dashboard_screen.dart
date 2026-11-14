import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/widgets/user_avatar_widget.dart';
import '../../auth/state/auth_provider.dart';
import '../../tasks/models/task_assignment_model.dart';
import 'data/admin_repository.dart';
import 'models/admin_dashboard_model.dart';
import 'state/admin_provider.dart';
import 'widgets/admin_tasks_view.dart';
import 'widgets/admin_rewards_view.dart';
import 'widgets/admin_users_view.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const _AdminHomeTab(),
      const AdminTasksView(),
      const AdminRewardsView(),
      const AdminUsersView(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFEEF2FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF6366F1)),
            label: 'Ringkasan',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: Color(0xFF6366F1)),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard_rounded, color: Color(0xFF6366F1)),
            label: 'Hadiah',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF6366F1)),
            label: 'Pengguna',
          ),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends ConsumerStatefulWidget {
  const _AdminHomeTab();

  @override
  ConsumerState<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<_AdminHomeTab> {
  String _dateMode = 'today'; // 'today', 'yesterday', 'tomorrow', 'dayAfter', 'custom'
  DateTime? _customDate;

  final DateTime _today = DateTime.now();
  late final DateTime _yesterday = _today.subtract(const Duration(days: 1));
  late final DateTime _tomorrow = _today.add(const Duration(days: 1));
  late final DateTime _dayAfter = _today.add(const Duration(days: 2));

  String _getActiveDateYmd() {
    if (_dateMode == 'yesterday') return AppDateUtils.formatYmd(_yesterday);
    if (_dateMode == 'tomorrow') return AppDateUtils.formatYmd(_tomorrow);
    if (_dateMode == 'dayAfter') return AppDateUtils.formatYmd(_dayAfter);
    if (_dateMode == 'custom' && _customDate != null) return AppDateUtils.formatYmd(_customDate!);
    return AppDateUtils.formatYmd(_today);
  }

  bool _isFutureDate() {
    final active = _getActiveDateYmd();
    final today = AppDateUtils.formatYmd(_today);
    return active.compareTo(today) > 0;
  }

  void _selectDate(String mode, {DateTime? custom}) {
    setState(() {
      _dateMode = mode;
      _customDate = custom;
    });

    final notifier = ref.read(adminDashboardNotifierProvider.notifier);
    if (mode == 'today') {
      notifier.resetToToday();
    } else {
      notifier.setDateFilter(_getActiveDateYmd());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardAsync = ref.watch(adminDashboardNotifierProvider);
    final activeDateYmd = _getActiveDateYmd();
    final worshipAsync = ref.watch(adminWorshipSummaryProvider(activeDateYmd));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Row(
          children: [
            UserAvatarWidget(
              avatarUrl: user?.fullAvatarUrl,
              name: user?.name,
              userId: user?.id,
              size: 34,
              borderRadius: 10,
              canEdit: true,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                    children: const [
                      TextSpan(text: 'Family'),
                      TextSpan(text: 'Task', style: TextStyle(color: Color(0xFF6366F1))),
                    ],
                  ),
                ),
                Text(
                  'Orang Tua • ${user?.name ?? 'Admin'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              'Admin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4338CA),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 20),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.read(adminDashboardNotifierProvider.notifier).refresh();
              ref.invalidate(adminWorshipSummaryProvider(activeDateYmd));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            tooltip: 'Keluar Akun',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar Akun?'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun Orang Tua?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(adminDashboardNotifierProvider.notifier).refresh();
          ref.invalidate(adminWorshipSummaryProvider(activeDateYmd));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- DATE SELECTOR STRIP (KEMARIN, HARI INI, BESOK, LUSA, CUSTOM) ---
              Container(
                padding: const EdgeInsets.all(12),
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
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Text(
                          'JADWAL TUGAS:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDatePill(
                            label: 'Kemarin (${DateFormat('dd MMM').format(_yesterday)})',
                            isSelected: _dateMode == 'yesterday',
                            onTap: () => _selectDate('yesterday'),
                          ),
                          const SizedBox(width: 6),
                          _buildDatePill(
                            label: 'Hari Ini (${DateFormat('dd MMM').format(_today)})',
                            isSelected: _dateMode == 'today',
                            onTap: () => _selectDate('today'),
                          ),
                          const SizedBox(width: 6),
                          _buildDatePill(
                            label: 'Besok (${DateFormat('dd MMM').format(_tomorrow)})',
                            isSelected: _dateMode == 'tomorrow',
                            onTap: () => _selectDate('tomorrow'),
                          ),
                          const SizedBox(width: 6),
                          _buildDatePill(
                            label: 'Lusa (${DateFormat('dd MMM').format(_dayAfter)})',
                            isSelected: _dateMode == 'dayAfter',
                            onTap: () => _selectDate('dayAfter'),
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
                                _selectDate('custom', custom: picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: _dateMode == 'custom' ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _dateMode == 'custom' ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 14,
                                    color: _dateMode == 'custom' ? Colors.white : const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _dateMode == 'custom' && _customDate != null
                                        ? DateFormat('dd MMM yyyy').format(_customDate!)
                                        : 'Pilih Tanggal',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _dateMode == 'custom' ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_dateMode != 'today') ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _selectDate('today'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '✕ Reset',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Menampilkan: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(activeDateYmd))}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4338CA),
                            ),
                          ),
                          if (_isFutureDate()) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC7D2FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'MENDATANG',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF312E81),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              dashboardAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Gagal memuat ringkasan: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 3 STAT COUNTERS ---
                    Row(
                      children: [
                        _buildStatBox(
                          'Total Tugas',
                          '${data.totalTasksToday}',
                          const Color(0xFF6366F1),
                          Icons.checklist_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Disetujui',
                          '${data.totalApprovedToday}',
                          const Color(0xFF10B981),
                          Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildStatBox(
                          'Perlu Review',
                          '${data.pendingReviews.length}',
                          const Color(0xFFF59E0B),
                          Icons.pending_actions_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // --- PENDING REVIEWS QUEUE ---
                    if (data.pendingReviews.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                'Perlu Peninjauan Tugas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${data.pendingReviews.length} permintaan',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...data.pendingReviews.map((task) => _buildReviewCard(context, ref, task)),
                      const SizedBox(height: 18),
                    ],

                    // --- PANTAU IBADAH HARIAN ANAK (SHOLAT 5 WAKTU & NGAJI) ---
                    worshipAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (worshipList) {
                        if (worshipList.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🕌', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  'Pantau Ibadah Harian Anak',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...worshipList.map((w) => _buildWorshipSummaryCard(w)),
                            const SizedBox(height: 18),
                          ],
                        );
                      },
                    ),

                    // --- KEMAJUAN & DAFTAR TUGAS ANAK (HARI INI & HARI LAIN) ---
                    Row(
                      children: [
                        const Icon(Icons.family_restroom, size: 20, color: Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        Text(
                          'Kemajuan & Daftar Tugas Anak',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...data.children.map((c) => _buildChildDetailCard(c, activeDateYmd)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorshipSummaryCard(AdminChildWorshipModel w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  UserAvatarWidget(
                    avatarUrl: w.avatarUrl,
                    name: w.userName,
                    userId: w.userId,
                    size: 28,
                    isCircle: true,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    w.userName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: w.quranDone ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      w.quranDone ? '📖 Ngaji ✓' : '📖 Belum Ngaji',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: w.quranDone ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${w.totalPointsEarned}p',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildPrayerPillCell('Subuh', w.subuh),
              const SizedBox(width: 4),
              _buildPrayerPillCell('Dzuhur', w.dzuhur),
              const SizedBox(width: 4),
              _buildPrayerPillCell('Ashar', w.ashar),
              const SizedBox(width: 4),
              _buildPrayerPillCell('Maghrib', w.maghrib),
              const SizedBox(width: 4),
              _buildPrayerPillCell('Isya', w.isya),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerPillCell(String prayerName, int status) {
    final isMosque = status == 2;
    final isSolo = status == 1;
    final isDone = isMosque || isSolo;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              prayerName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMosque ? '🕌 +5p' : (isSolo ? '🏫 +3p' : '○ Belum'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: isDone ? const Color(0xFF059669) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CHILD DETAIL CARD INCLUDING TASK LIST ---
  Widget _buildChildDetailCard(ChildProgressModel c, String activeDateYmd) {
    final progress = c.tasksToday > 0 ? (c.tasksCompleted / c.tasksToday) : 0.0;
    final isFuture = _isFutureDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Profile Header
          Row(
            children: [
              UserAvatarWidget(
                avatarUrl: c.avatarUrl,
                name: c.name,
                userId: c.userId,
                size: 44,
                isCircle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      children: [
                        Text(
                          '★ ${c.totalPoints} total poin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        Text(
                          '• 🔥 ${c.currentStreak} hari',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${c.tasksCompleted}/${c.tasksToday} Selesai',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF10B981),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // Task List Sub-header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Tugas (${c.todayTasks.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(activeDateYmd)),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Task Items List
          if (c.todayTasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Tidak ada tugas pada periode ini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ...c.todayTasks.map((t) => _buildChildTaskItem(t, isFuture: isFuture)),
        ],
      ),
    );
  }

  Widget _buildChildTaskItem(TaskAssignmentModel task, {required bool isFuture}) {
    // Status color & label
    String statusLabel = 'Belum Selesai';
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusColor = const Color(0xFF475569);

    if (isFuture) {
      statusLabel = 'Terjadwal';
      statusBg = const Color(0xFFEEF2FF);
      statusColor = const Color(0xFF4338CA);
    } else if (task.isApproved) {
      statusLabel = 'Selesai ✓';
      statusBg = const Color(0xFFECFDF5);
      statusColor = const Color(0xFF059669);
    } else if (task.isSubmitted) {
      statusLabel = 'Menunggu Review';
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
    } else if (task.isRejected) {
      statusLabel = 'Perlu Perbaikan';
      statusBg = const Color(0xFFFFF1F2);
      statusColor = const Color(0xFFE11D48);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(task.iconEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (task.targetTime != null && task.targetTime!.isNotEmpty)
                  Text(
                    '⏰ Target: ${task.targetTime}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${task.points}p',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, WidgetRef ref, TaskAssignmentModel task) {
    String? fullPhotoUrl;
    if (task.proofPhotoUrl != null && task.proofPhotoUrl!.isNotEmpty) {
      if (task.proofPhotoUrl!.startsWith('http')) {
        fullPhotoUrl = task.proofPhotoUrl;
      } else {
        fullPhotoUrl = '${ApiConstants.baseHost}/${task.proofPhotoUrl!.replaceAll('\\', '/')}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(task.iconEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
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
                    Text(
                      'Oleh ${task.assignedToName ?? 'Anak'} • +${task.points} Poin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (task.submissionNote != null && task.submissionNote!.isNotEmpty) ...[
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
                'Catatan: "${task.submissionNote}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          if (fullPhotoUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showZoomPhoto(context, fullPhotoUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        fullPhotoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 140,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('Foto bukti tidak dapat dimuat'),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Perbesar', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => _showRejectDialog(context, ref, task),
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    final success = await ref
                        .read(adminDashboardNotifierProvider.notifier)
                        .approveTask(task.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Tugas disetujui! Poin bertambah 🎉' : 'Gagal menyetujui tugas.',
                          ),
                          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Setujui (ACC) ✨'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showZoomPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, TaskAssignmentModel task) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Tolak Tugas',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan alasan penolakan untuk anak:',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Foto kurang jelas / belum rapi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await ref
                  .read(adminDashboardNotifierProvider.notifier)
                  .rejectTask(task.id, reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Tugas telah ditolak.' : 'Gagal menolak tugas.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Kirim Penolakan'),
          ),
        ],
      ),
    );
  }
}
