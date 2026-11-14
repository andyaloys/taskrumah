class ApiConstants {
  static const String baseUrl = 'https://familytask.web.id/api';
  static const String baseHost = 'https://familytask.web.id';

  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String quickUsers = '/auth/quick-users';

  // Dashboard
  static const String adminDashboard = '/dashboard/admin';
  static const String childDashboard = '/dashboard/child';

  // Tasks
  static const String tasks = '/tasks';
  static const String extraTasks = '/tasks/extra';
  static const String taskAssignments = '/task-assignments';
  static const String taskSchedule = '/task-assignments/schedule';
  static const String submitExtraTask = '/task-assignments/submit-extra';
  static String submitTask(String id) => '/task-assignments/$id/submit';
  static String approveTask(String id) => '/task-assignments/$id/approve';
  static String rejectTask(String id) => '/task-assignments/$id/reject';
  static String resetTask(String id) => '/task-assignments/$id/reset';

  // Worship
  static const String worshipMy = '/worship/my';
  static const String worshipSave = '/worship/save';
  static const String worshipSetting = '/worship/setting';
  static const String worshipAdminSummary = '/worship/admin/summary';

  // Rewards
  static const String rewards = '/rewards';
  static const String redemptions = '/rewards/redemptions';
  static String redeemReward(String id) => '/rewards/$id/redeem';
  static String processRedemption(String id) => '/rewards/redemptions/$id';

  // Users
  static const String users = '/users';
  static const String children = '/users/children';
  static String userDetail(String id) => '/users/$id';
}
