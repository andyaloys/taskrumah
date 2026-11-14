import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_date_utils.dart';
import '../state/worship_provider.dart';

class WorshipScreen extends ConsumerStatefulWidget {
  const WorshipScreen({super.key});

  @override
  ConsumerState<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends ConsumerState<WorshipScreen> {
  String _dateMode = 'today'; // 'today', 'yesterday', 'twoDaysAgo', 'custom'
  DateTime? _customDate;

  final DateTime _today = DateTime.now();
  late final DateTime _yesterday = _today.subtract(const Duration(days: 1));
  late final DateTime _twoDaysAgo = _today.subtract(const Duration(days: 2));

  String _getActiveDateYmd() {
    if (_dateMode == 'yesterday') return AppDateUtils.formatYmd(_yesterday);
    if (_dateMode == 'twoDaysAgo') return AppDateUtils.formatYmd(_twoDaysAgo);
    if (_dateMode == 'custom' && _customDate != null) return AppDateUtils.formatYmd(_customDate!);
    return AppDateUtils.formatYmd(_today);
  }

  bool _isReadOnly() {
    try {
      final active = DateTime.parse(_getActiveDateYmd());
      final todayMidnight = DateTime(_today.year, _today.month, _today.day);
      final activeMidnight = DateTime(active.year, active.month, active.day);
      final diff = todayMidnight.difference(activeMidnight).inDays;
      return diff > 2 || diff < 0; // Lebih dari 2 hari lalu atau masa depan
    } catch (_) {
      return false;
    }
  }

  void _selectDate(String mode, {DateTime? custom}) {
    setState(() {
      _dateMode = mode;
      _customDate = custom;
    });
    ref.read(worshipNotifierProvider.notifier).changeDate(_getActiveDateYmd());
  }

  String _formatDateTitle(String dateYmd) {
    try {
      final d = DateTime.parse(dateYmd);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(d);
    } catch (_) {
      try {
        final d = DateTime.parse(dateYmd);
        return DateFormat('EEEE, dd MMMM yyyy').format(d);
      } catch (_) {
        return dateYmd;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final worshipAsync = ref.watch(worshipNotifierProvider);
    final notifier = ref.read(worshipNotifierProvider.notifier);
    final settingAsync = ref.watch(worshipSettingProvider);
    final setting = settingAsync.value;

    final int soloPts = (setting?['soloPoints'] as num?)?.toInt() ?? 3;
    final int mosquePts = (setting?['mosquePoints'] as num?)?.toInt() ?? 5;
    final int quranPts = (setting?['quranPoints'] as num?)?.toInt() ?? 5;

    final bool readOnly = _isReadOnly();
    final String activeDateYmd = _getActiveDateYmd();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Catatan Ibadah Sholat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B), size: 20),
            tooltip: 'Segarkan',
            onPressed: () {
              ref.read(worshipNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DATE SELECTOR STRIP ---
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
                      const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'PILIH TANGGAL IBADAH:',
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
                          label: 'Hari Ini',
                          isSelected: _dateMode == 'today',
                          onTap: () => _selectDate('today'),
                        ),
                        const SizedBox(width: 6),
                        _buildDatePill(
                          label: 'Kemarin',
                          isSelected: _dateMode == 'yesterday',
                          onTap: () => _selectDate('yesterday'),
                        ),
                        const SizedBox(width: 6),
                        _buildDatePill(
                          label: '2 Hari Lalu',
                          isSelected: _dateMode == 'twoDaysAgo',
                          onTap: () => _selectDate('twoDaysAgo'),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customDate ?? _today,
                              firstDate: DateTime(2025),
                              lastDate: _today,
                            );
                            if (picked != null) {
                              _selectDate('custom', custom: picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: _dateMode == 'custom' ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _dateMode == 'custom' ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
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
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Tanggal: ${_formatDateTitle(activeDateYmd)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Locked Warning Banner
            if (readOnly) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan ibadah lebih dari 2 hari yang lalu telah dikunci (hanya baca).',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Content loaded from provider
            worshipAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
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

                return Column(
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
                                  _dateMode == 'today'
                                      ? 'Ibadah Hari Ini'
                                      : 'Ibadah (${DateFormat('dd MMM').format(DateTime.parse(activeDateYmd))})',
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${record.totalPointsEarned}p',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

                    _buildPrayerTile(
                      'Subuh',
                      record.subuh,
                      soloPts,
                      mosquePts,
                      readOnly,
                      (val) => _handleUpdate(readOnly, () => notifier.updatePrayer('subuh', val)),
                    ),
                    const SizedBox(height: 10),
                    _buildPrayerTile(
                      'Dzuhur',
                      record.dzuhur,
                      soloPts,
                      mosquePts,
                      readOnly,
                      (val) => _handleUpdate(readOnly, () => notifier.updatePrayer('dzuhur', val)),
                    ),
                    const SizedBox(height: 10),
                    _buildPrayerTile(
                      'Ashar',
                      record.ashar,
                      soloPts,
                      mosquePts,
                      readOnly,
                      (val) => _handleUpdate(readOnly, () => notifier.updatePrayer('ashar', val)),
                    ),
                    const SizedBox(height: 10),
                    _buildPrayerTile(
                      'Maghrib',
                      record.maghrib,
                      soloPts,
                      mosquePts,
                      readOnly,
                      (val) => _handleUpdate(readOnly, () => notifier.updatePrayer('maghrib', val)),
                    ),
                    const SizedBox(height: 10),
                    _buildPrayerTile(
                      'Isya',
                      record.isya,
                      soloPts,
                      mosquePts,
                      readOnly,
                      (val) => _handleUpdate(readOnly, () => notifier.updatePrayer('isya', val)),
                    ),

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
                            onChanged: readOnly
                                ? (_) => _showLockedSnackBar()
                                : (_) => notifier.toggleQuran(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpdate(bool readOnly, VoidCallback callback) {
    if (readOnly) {
      _showLockedSnackBar();
      return;
    }
    callback();
  }

  void _showLockedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan ibadah lebih dari 2 hari yang lalu telah dikunci.'),
        backgroundColor: Color(0xFFDC2626),
        duration: Duration(seconds: 2),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
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

  Widget _buildPrayerTile(
    String name,
    int status,
    int soloPts,
    int mosquePts,
    bool readOnly,
    Function(int) onSelect,
  ) {
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
                readOnly: readOnly,
                onTap: () => onSelect(0),
              ),
              const SizedBox(width: 8),
              _buildChoice(
                label: 'Sendiri (+${soloPts}p)',
                selected: status == 1,
                color: const Color(0xFF0284C7),
                readOnly: readOnly,
                onTap: () => onSelect(1),
              ),
              const SizedBox(width: 8),
              _buildChoice(
                label: 'Masjid (+${mosquePts}p)',
                selected: status == 2,
                color: const Color(0xFF059669),
                readOnly: readOnly,
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
    required bool readOnly,
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
