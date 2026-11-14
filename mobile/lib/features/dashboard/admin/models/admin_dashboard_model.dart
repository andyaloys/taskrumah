import '../../../tasks/models/task_assignment_model.dart';

class ChildProgressModel {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalPoints;
  final int currentStreak;
  final int tasksToday;
  final int tasksCompleted;
  final int tasksPending;
  final List<TaskAssignmentModel> todayTasks;
  final int weeklyPoints;

  ChildProgressModel({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.totalPoints,
    required this.currentStreak,
    required this.tasksToday,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.todayTasks,
    required this.weeklyPoints,
  });

  factory ChildProgressModel.fromJson(Map<String, dynamic> json) {
    final rawTasks = (json['todayTasks'] as List<dynamic>?) ?? [];
    return ChildProgressModel(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      tasksToday: (json['tasksToday'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      tasksPending: (json['tasksPending'] as num?)?.toInt() ?? 0,
      todayTasks: rawTasks.map((e) => TaskAssignmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      weeklyPoints: (json['weeklyPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardModel {
  final List<ChildProgressModel> children;
  final List<TaskAssignmentModel> pendingReviews;
  final int totalTasksToday;
  final int totalApprovedToday;
  final String? weekStart;
  final String? weekEnd;
  final int weekOffset;
  final String? targetDate;

  AdminDashboardModel({
    required this.children,
    required this.pendingReviews,
    required this.totalTasksToday,
    required this.totalApprovedToday,
    this.weekStart,
    this.weekEnd,
    this.weekOffset = 0,
    this.targetDate,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = (json['children'] as List<dynamic>?) ?? [];
    final rawReviews = (json['pendingReviews'] as List<dynamic>?) ?? [];

    return AdminDashboardModel(
      children: rawChildren.map((e) => ChildProgressModel.fromJson(e as Map<String, dynamic>)).toList(),
      pendingReviews: rawReviews.map((e) => TaskAssignmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalTasksToday: (json['totalTasksToday'] as num?)?.toInt() ?? 0,
      totalApprovedToday: (json['totalApprovedToday'] as num?)?.toInt() ?? 0,
      weekStart: json['weekStart'] as String?,
      weekEnd: json['weekEnd'] as String?,
      weekOffset: (json['weekOffset'] as num?)?.toInt() ?? 0,
      targetDate: json['targetDate'] as String?,
    );
  }
}
