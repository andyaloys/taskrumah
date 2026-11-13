import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../auth/state/auth_provider.dart';
import '../data/task_repository.dart';
import '../models/task_assignment_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TaskRepository(client);
});

enum DatePreset { today, yesterday, tomorrow }

class TaskFilterState {
  final DatePreset preset;
  final String dateYmd;

  TaskFilterState({
    required this.preset,
    required this.dateYmd,
  });

  factory TaskFilterState.today() {
    return TaskFilterState(
      preset: DatePreset.today,
      dateYmd: AppDateUtils.todayYmd(),
    );
  }
}

class TasksNotifier extends AsyncNotifier<List<TaskAssignmentModel>> {
  DatePreset _preset = DatePreset.today;
  String _dateYmd = AppDateUtils.todayYmd();

  DatePreset get currentPreset => _preset;
  String get currentDateYmd => _dateYmd;

  @override
  Future<List<TaskAssignmentModel>> build() async {
    return _fetch();
  }

  Future<List<TaskAssignmentModel>> _fetch() async {
    final repo = ref.read(taskRepositoryProvider);
    return await repo.getSchedule(_dateYmd);
  }

  Future<void> changeDatePreset(DatePreset preset) async {
    _preset = preset;
    switch (preset) {
      case DatePreset.today:
        _dateYmd = AppDateUtils.todayYmd();
        break;
      case DatePreset.yesterday:
        _dateYmd = AppDateUtils.yesterdayYmd();
        break;
      case DatePreset.tomorrow:
        _dateYmd = AppDateUtils.tomorrowYmd();
        break;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> submitTask(String assignmentId, {String? note, File? photo}) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.submitTask(assignmentId, note: note, photo: photo);
    await refresh();
  }
}

final tasksNotifierProvider = AsyncNotifierProvider<TasksNotifier, List<TaskAssignmentModel>>(() {
  return TasksNotifier();
});
