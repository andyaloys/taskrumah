import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../data/admin_repository.dart';
import '../state/admin_provider.dart';

class AdminWorshipView extends ConsumerStatefulWidget {
  const AdminWorshipView({super.key});

  @override
  ConsumerState<AdminWorshipView> createState() => _AdminWorshipViewState();
}

class _AdminWorshipViewState extends ConsumerState<AdminWorshipView> {
  String _selectedDate = AppDateUtils.todayYmd();

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(adminWorshipSummaryProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pemantauan Ibadah Anak',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminWorshipSummaryProvider(_selectedDate));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker / selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanggal: $_selectedDate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      ActionChip(
                        label: const Text('Hari Ini'),
                        onPressed: () {
                          setState(() {
                            _selectedDate = AppDateUtils.todayYmd();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Kemarin'),
                        onPressed: () {
                          setState(() {
                            _selectedDate = AppDateUtils.yesterdayYmd();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              summaryAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Gagal memuat ibadah: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (children) {
                  if (children.isEmpty) {
                    return const Center(child: Text('Tidak ada data anak aktif.'));
                  }

                  return Column(
                    children: children.map((c) => _buildChildWorshipCard(c)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildWorshipCard(AdminChildWorshipModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                child: Text(
                  c.userName.isNotEmpty ? c.userName[0] : 'A',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '+${c.totalPointsEarned} poin ibadah terkumpul',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Tilawah badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.quranDone ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: c.quranDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.quranDone ? '📖 Sudah Ngaji' : '📖 Belum Ngaji',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: c.quranDone ? const Color(0xFF059669) : const Color(0xFF64748B),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 5 Sholat Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPrayerPill('Subuh', c.subuh),
              _buildPrayerPill('Dzuhur', c.dzuhur),
              _buildPrayerPill('Ashar', c.ashar),
              _buildPrayerPill('Maghrib', c.maghrib),
              _buildPrayerPill('Isya', c.isya),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerPill(String name, int status) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (status) {
      case 2: // Mosque
        bg = const Color(0xFFD1FAE5);
        border = const Color(0xFF10B981);
        text = const Color(0xFF065F46);
        label = 'Masjid';
        break;
      case 1: // Solo
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFF60A5FA);
        text = const Color(0xFF1E40AF);
        label = 'Sendiri';
        break;
      default: // None
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF94A3B8);
        label = 'Belum';
        break;
    }

    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ),
      ],
    );
  }
}
