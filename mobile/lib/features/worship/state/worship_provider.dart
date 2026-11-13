import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../auth/state/auth_provider.dart';
import '../data/worship_repository.dart';
import '../models/worship_model.dart';

final worshipRepositoryProvider = Provider<WorshipRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return WorshipRepository(client);
});

class WorshipNotifier extends AsyncNotifier<DailyWorshipModel?> {
  String _dateYmd = AppDateUtils.todayYmd();

  String get currentDateYmd => _dateYmd;

  @override
  Future<DailyWorshipModel?> build() async {
    return _fetch();
  }

  Future<DailyWorshipModel?> _fetch() async {
    final repo = ref.read(worshipRepositoryProvider);
    return await repo.getMyWorship(_dateYmd);
  }

  Future<void> changeDate(String dateYmd) async {
    _dateYmd = dateYmd;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> updatePrayer(String prayerName, int newStatus) async {
    final current = state.value;
    if (current == null) return;

    DailyWorshipModel updated;
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        updated = current.copyWith(subuh: newStatus);
        break;
      case 'dzuhur':
        updated = current.copyWith(dzuhur: newStatus);
        break;
      case 'ashar':
        updated = current.copyWith(ashar: newStatus);
        break;
      case 'maghrib':
        updated = current.copyWith(maghrib: newStatus);
        break;
      case 'isya':
        updated = current.copyWith(isya: newStatus);
        break;
      default:
        return;
    }

    state = AsyncValue.data(updated);
    try {
      final repo = ref.read(worshipRepositoryProvider);
      await repo.saveWorship(updated);
    } catch (e) {
      // Revert if error
      state = AsyncValue.data(current);
      rethrow;
    }
  }

  Future<void> toggleQuran() async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(quranDone: !current.quranDone);
    state = AsyncValue.data(updated);
    try {
      final repo = ref.read(worshipRepositoryProvider);
      await repo.saveWorship(updated);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final worshipNotifierProvider = AsyncNotifierProvider<WorshipNotifier, DailyWorshipModel?>(() {
  return WorshipNotifier();
});
