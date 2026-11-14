import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/user_avatar_widget.dart';
import '../../auth/state/auth_provider.dart';
import '../../tasks/models/task_assignment_model.dart';
import '../../tasks/screens/submit_extra_task_dialog.dart';
import '../../tasks/screens/submit_task_dialog.dart';
import '../../tasks/state/tasks_provider.dart';
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
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final List<Widget> pages = [
      _ChildHomeTab(onSwitchTab: _switchTab),
      const WorshipScreen(),
      const RewardShopScreen(),
      const ChildProfileView(),
    ];

    return Scaffold(
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
                  'Hai, ${user?.name ?? 'Anak Hebat'}',
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('★ ', style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  '${user?.totalPoints ?? 0}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'poin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
            tooltip: 'Keluar Akun',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar Akun?'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
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

class _ChildHomeTab extends ConsumerStatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const _ChildHomeTab({required this.onSwitchTab});

  @override
  ConsumerState<_ChildHomeTab> createState() => _ChildHomeTabState();
}

class _ChildHomeTabState extends ConsumerState<_ChildHomeTab> {
  DateTime _selectedDate = DateTime.now();

  String _formatYmd(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<DateTime> _getWeekDays(DateTime refDate) {
    final diff = (refDate.weekday - DateTime.monday) % 7;
    final monday = DateTime(refDate.year, refDate.month, refDate.day).subtract(Duration(days: diff));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Sen';
      case DateTime.tuesday:
        return 'Sel';
      case DateTime.wednesday:
        return 'Rab';
      case DateTime.thursday:
        return 'Kam';
      case DateTime.friday:
        return 'Jum';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Min';
      default:
        return '';
    }
  }

  String _getDayFullName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[(month - 1).clamp(0, 11)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'SELAMAT PAGI';
    if (hour < 15) return 'SELAMAT SIANG';
    if (hour < 18) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final worshipAsync = ref.watch(worshipNotifierProvider);

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final selectedMidnight = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = selectedMidnight == todayMidnight;
    final isYesterday = selectedMidnight == todayMidnight.subtract(const Duration(days: 1));
    final isFuture = selectedMidnight.isAfter(todayMidnight);

    final weekDays = _getWeekDays(_selectedDate);

    // Calculate completed vs today tasks count
    final tasksList = tasksAsync.value ?? [];
    final tasksTodayCount = tasksList.length;
    final tasksCompletedCount = tasksList.where((t) => t.isApproved).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Web Slate-50 background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(tasksNotifierProvider.notifier).refresh();
            await ref.read(worshipNotifierProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting Card (Exactly like Web)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), // Slate-900
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      UserAvatarWidget(
                        avatarUrl: user?.fullAvatarUrl,
                        name: user?.name,
                        userId: user?.id,
                        size: 46,
                        borderRadius: 14,
                        canEdit: true,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF818CF8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Halo, ${user?.name ?? 'Anak Hebat'}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF94A3B8), size: 12),
                            const SizedBox(width: 6),
                            Text(
                              '${now.day} ${_getMonthName(now.month)} ${now.year}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Stats Grid (2x2 Balanced - Exactly like Web)
                Row(
                  children: [
                    _buildStatCard(
                      value: '${user?.totalPoints ?? 0}',
                      label: 'Total Poin',
                      valueColor: const Color(0xFFD97706), // Amber-600
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      value: '+${user?.totalPoints ?? 0}',
                      label: 'Poin Minggu Ini',
                      valueColor: const Color(0xFF4F46E5), // Indigo-600
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard(
                      value: '${user?.currentStreak ?? 0}',
                      label: 'Hari Berturut',
                      valueColor: const Color(0xFF1E293B), // Slate-800
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      value: '$tasksCompletedCount/$tasksTodayCount',
                      label: 'Tugas Selesai',
                      valueColor: const Color(0xFF059669), // Emerald-600
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Kartu Status Ibadah Hari Ini (5 Sholat Badges + Ngaji - Exactly like Web)
                worshipAsync.maybeWhen(
                  data: (record) {
                    final subuh = record?.subuh ?? 0;
                    final dzuhur = record?.dzuhur ?? 0;
                    final ashar = record?.ashar ?? 0;
                    final maghrib = record?.maghrib ?? 0;
                    final isya = record?.isya ?? 0;
                    final quranDone = record?.quranDone ?? false;
                    final totalWorshipPts = record?.totalPointsEarned ?? 0;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'IBADAH & SHOLAT 5 WAKTU',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '🟢 Hijau = Sudah • Hari ini: +${totalWorshipPts}p',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: const Color(0xFF059669),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => widget.onSwitchTab(1), // Switch to Ibadah tab
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE0E7FF)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Isi / Ubah',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4F46E5),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text('➔', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5 Sholat Columns (Web style)
                          Row(
                            children: [
                              _buildWebPrayerPill('Subuh', subuh),
                              const SizedBox(width: 6),
                              _buildWebPrayerPill('Dzuhur', dzuhur),
                              const SizedBox(width: 6),
                              _buildWebPrayerPill('Ashar', ashar),
                              const SizedBox(width: 6),
                              _buildWebPrayerPill('Maghrib', maghrib),
                              const SizedBox(width: 6),
                              _buildWebPrayerPill('Isya', isya),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Ngaji Status Bar (Web style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('📖 ', style: TextStyle(fontSize: 13)),
                                    Text(
                                      'Ngaji / Tilawah Qur\'an',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: quranDone ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: quranDone ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    quranDone ? '✓ Sudah Ngaji' : 'Belum Mengisi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: quranDone ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),

                // 4. Week Calendar Strip (7 Days: Sen, Sel, Rab, Kam, Jum, Sab, Min)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDays.map((d) {
                      final isSelected = d.year == _selectedDate.year &&
                          d.month == _selectedDate.month &&
                          d.day == _selectedDate.day;
                      final isCurrentDay = d.year == now.year && d.month == now.month && d.day == now.day;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = d;
                            });
                            ref.read(tasksNotifierProvider.notifier).changeDate(_formatYmd(d));
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F172A) // Selected dark slate
                                  : (isCurrentDay
                                      ? const Color(0xFFEEF2FF) // Today light indigo
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : (isCurrentDay ? const Color(0xFFC7D2FE) : Colors.transparent),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getDayName(d.weekday),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFCBD5E1)
                                        : (isCurrentDay ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${d.day}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (isCurrentDay ? const Color(0xFF4F46E5) : const Color(0xFF0F172A)),
                                  ),
                                ),
                                if (isCurrentDay)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Task Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday
                                ? 'Tugas Hari Ini (${_getDayFullName(_selectedDate.weekday)}, ${_selectedDate.day} ${_getMonthName(_selectedDate.month)})'
                                : (isYesterday
                                    ? 'Tugas Kemarin (${_getDayFullName(_selectedDate.weekday)}, ${_selectedDate.day} ${_getMonthName(_selectedDate.month)})'
                                    : 'Tugas ${_getDayFullName(_selectedDate.weekday)}, ${_selectedDate.day} ${_getMonthName(_selectedDate.month)}'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isToday
                                ? 'Selesaikan tugasmu hari ini'
                                : (isYesterday ? 'Tugas kemarin masih bisa dikerjakan susulan' : 'Jadwal tugas'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA), // Purple-600 (Web style)
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Text('🌟', style: TextStyle(fontSize: 12)),
                          label: Text(
                            '+ Lapor Tugas',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => SubmitExtraTaskDialog.show(context),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tasksList.length} tugas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Notice Banner if Yesterday
                if (isYesterday)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB), // Amber-50
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history, color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Tugas Kemarin',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                              Text(
                                'Tugas H-1 masih dapat dikerjakan susulan jika kemarin terlewat.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 6. Tasks List (Cards formatted exactly like Web)
                tasksAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
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
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('📋', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada tugas pada hari ini',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: tasks.map((task) => _buildWebTaskCard(context, task, isYesterday, isFuture)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPrayerPill(String name, int status) {
    final bool done = status > 0;
    final bool mosque = status == 2;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: done ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: done ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    done ? (mosque ? '🕌' : '✓') : '○',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: done ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(width: 2),
                    Text(
                      mosque ? '+5p' : '+3p',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebTaskCard(
    BuildContext context,
    TaskAssignmentModel task,
    bool isYesterday,
    bool isFuture,
  ) {
    Color statusBg;
    Color statusBorder;
    Color statusText;
    String statusLabel;

    if (task.isApproved) {
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusText = const Color(0xFF047857);
      statusLabel = 'Disetujui';
    } else if (task.isSubmitted) {
      statusBg = const Color(0xFFF0F9FF);
      statusBorder = const Color(0xFFBAE6FD);
      statusText = const Color(0xFF0369A1);
      statusLabel = 'Terkirim';
    } else if (task.isRejected) {
      statusBg = const Color(0xFFFFF1F2);
      statusBorder = const Color(0xFFFECDD3);
      statusText = const Color(0xFFBE123C);
      statusLabel = 'Ditolak';
    } else {
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusText = const Color(0xFFB45309);
      statusLabel = isYesterday ? 'Terlambat' : 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              // 40x40 Emoji Container (Web style)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Text(task.iconEmoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
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
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Points pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '+${task.points} poin',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                        if (task.targetTime != null && task.targetTime!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: Text(
                              '⏰ ${task.targetTime}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action button on the right (Web style)
              if (isFuture)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('Terjadwal', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                )
              else if (task.isApproved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      SizedBox(width: 4),
                      Text('Disetujui', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                    ],
                  ),
                )
              else if (task.isSubmitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    'Menunggu Review',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                )
              else if (task.isRejected)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48), // Rose-600
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => SubmitTaskDialog.show(context, task),
                  child: const Text('Perbaiki', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isYesterday ? const Color(0xFF4F46E5) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => SubmitTaskDialog.show(context, task),
                  child: Text(
                    isYesterday ? 'Kerjakan Susulan' : 'Kerjakan',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          if (task.rejectionReason != null && task.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text(
                'Catatan penolakan: ${task.rejectionReason}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
