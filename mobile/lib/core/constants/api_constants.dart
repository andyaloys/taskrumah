class ApiConstants {
  static const String baseUrl = 'https://familytask.web.id/api';
  static const String baseHost = 'https://familytask.web.id';

  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';

  // Tasks
  static const String tasks = '/tasks';
  static const String taskAssignments = '/task-assignments';
  static const String myTodayAssignments = '/task-assignments/my-today';
  static const String myAssignmentsByDate = '/task-assignments/my-date';
  static String submitTask(int id) => '/task-assignments/$id/submit';
  static String approveTask(int id) => '/task-assignments/$id/approve';
  static String rejectTask(int id) => '/task-assignments/$id/reject';
  static String resetTask(int id) => '/task-assignments/$id/reset';

  // Worship
  static const String worshipMy = '/worship/my';
  static const String worshipCheck = '/worship/check';
  static const String worshipAdminSummary = '/worship/admin-summary';

  // Rewards
  static const String rewards = '/rewards';
  static const String myClaims = '/rewards/my-claims';
  static String claimReward(int id) => '/rewards/$id/claim';
  static String approveClaim(int id) => '/rewards/claims/$id/approve';
  static String rejectClaim(int id) => '/rewards/claims/$id/reject';

  // Users / Children
  static const String users = '/users';
  static const String children = '/users/children';
  static String childDetail(int id) => '/users/$id';
}
