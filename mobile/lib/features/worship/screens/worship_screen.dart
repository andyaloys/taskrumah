import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../state/worship_provider.dart';

class WorshipScreen extends ConsumerWidget {
  const WorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worshipAsync = ref.watch(worshipNotifierProvider);
    final notifier = ref.read(worshipNotifierProvider.notifier);
    final settingAsync = ref.watch(worshipSettingProvider);
    final setting = settingAsync.value;

    final int soloPts = (setting?['soloPoints'] as num?)?.toInt() ?? 3;
    final int mosquePts = (setting?['mosquePoints'] as num?)?.toInt() ?? 5;
    final int quranPts = (setting?['quranPoints'] as num?)?.toInt() ?? 5;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Catatan Ibadah Sholat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: worshipAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(err.toString(), style: GoogleFonts.plusJakartaSans(color: AppColors.danger)),
          ),
        ),
        data: (record) {
          if (record == null) {
            return const Center(child: Text('Data ibadah tidak tersedia.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ibadah Hari Ini',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Masjid: +${mosquePts}p • Sendiri: +${soloPts}p • Ngaji: +${quranPts}p',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5 Daily Prayers
                Text(
                  'SHOLAT 5 WAKTU',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                _buildPrayerTile('Subuh', record.subuh, soloPts, mosquePts, (val) => notifier.updatePrayer('subuh', val)),
                const SizedBox(height: 10),
                _buildPrayerTile('Dzuhur', record.dzuhur, soloPts, mosquePts, (val) => notifier.updatePrayer('dzuhur', val)),
                const SizedBox(height: 10),
                _buildPrayerTile('Ashar', record.ashar, soloPts, mosquePts, (val) => notifier.updatePrayer('ashar', val)),
                const SizedBox(height: 10),
                _buildPrayerTile('Maghrib', record.maghrib, soloPts, mosquePts, (val) => notifier.updatePrayer('maghrib', val)),
                const SizedBox(height: 10),
                _buildPrayerTile('Isya', record.isya, soloPts, mosquePts, (val) => notifier.updatePrayer('isya', val)),

                const SizedBox(height: 24),

                // Quran Section
                Text(
                  'IBADAH SUNNAH / NGAJI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: record.quranDone ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF059669), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Membaca Al-Qur\'an / Iqro',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Minimal 1 lembar / surat pendek (+${quranPts} poin)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: record.quranDone,
                        activeColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (_) => notifier.toggleQuran(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerTile(String name, int status, int soloPts, int mosquePts, Function(int) onSelect) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChoice(
                label: 'Belum',
                selected: status == 0,
                color: const Color(0xFF64748B),
                onTap: () => onSelect(0),
              ),
              const SizedBox(width: 8),
              _buildChoice(
                label: 'Sendiri (+${soloPts}p)',
                selected: status == 1,
                color: const Color(0xFF0284C7),
                onTap: () => onSelect(1),
              ),
              const SizedBox(width: 8),
              _buildChoice(
                label: 'Masjid (+${mosquePts}p)',
                selected: status == 2,
                color: const Color(0xFF059669),
                onTap: () => onSelect(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoice({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
