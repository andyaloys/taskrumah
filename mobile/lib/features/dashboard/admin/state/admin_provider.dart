import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/state/auth_provider.dart';
import '../data/admin_repository.dart';
import '../models/admin_dashboard_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AdminRepository(client);
});

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardModel> {
  @override
  Future<AdminDashboardModel> build() async {
    return _fetch();
  }

  Future<AdminDashboardModel> _fetch() async {
    final repo = ref.read(adminRepositoryProvider);
    return await repo.getDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<bool> approveTask(String assignmentId) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.approveTask(assignmentId);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectTask(String assignmentId, String reason) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.rejectTask(assignmentId, reason);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminDashboardNotifierProvider = AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardModel>(() {
  return AdminDashboardNotifier();
});

final adminWorshipSummaryProvider = FutureProvider.family<List<AdminChildWorshipModel>, String>((ref, dateYmd) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.getWorshipSummary(dateYmd);
});

final adminTasksListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getTasks(activeOnly: false);
});

final adminWorshipSettingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getWorshipSetting();
});

final adminRewardsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getRewards();
});

final adminUsersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getUsers();
});
