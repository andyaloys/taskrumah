class ChoreTaskModel {
  final String id;
  final String title;
  final String? description;
  final int points;
  final String? iconEmoji;
  final bool isDaily;
  final String? targetTime;

  ChoreTaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.points,
    this.iconEmoji,
    required this.isDaily,
    this.targetTime,
  });

  factory ChoreTaskModel.fromJson(Map<String, dynamic> json) {
    return ChoreTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Tugas',
      description: json['description'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '⭐',
      isDaily: json['isDaily'] as bool? ?? false,
      targetTime: json['targetTime'] as String?,
    );
  }
}

class TaskAssignmentModel {
  final String id;
  final String taskId;
  final String rawTitle;
  final String? rawDescription;
  final int rawPoints;
  final String rawIconEmoji;
  final String? targetTime;
  final ChoreTaskModel? task;
  final String assignedToId;
  final String? assignedToName;
  final String? assignedToAvatarUrl;
  final String dueDate;
  final String status; // 'Pending', 'Submitted', 'Approved', 'Rejected'
  final String? submissionNote;
  final String? proofPhotoUrl;
  final String? completedAt;
  final String? rejectionReason;

  TaskAssignmentModel({
    required this.id,
    required this.taskId,
    required this.rawTitle,
    this.rawDescription,
    required this.rawPoints,
    required this.rawIconEmoji,
    this.targetTime,
    this.task,
    required this.assignedToId,
    this.assignedToName,
    this.assignedToAvatarUrl,
    required this.dueDate,
    required this.status,
    this.submissionNote,
    this.proofPhotoUrl,
    this.completedAt,
    this.rejectionReason,
  });

  bool get isPending => status == 'Pending';
  bool get isSubmitted => status == 'Submitted';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  String get title => rawTitle.isNotEmpty ? rawTitle : (task?.title ?? 'Tugas');
  String get description => rawDescription ?? (task?.description ?? '');
  int get points => rawPoints > 0 ? rawPoints : (task?.points ?? 0);
  String get iconEmoji => rawIconEmoji.isNotEmpty ? rawIconEmoji : (task?.iconEmoji ?? '📋');

  factory TaskAssignmentModel.fromJson(Map<String, dynamic> json) {
    // Backend TaskAssignmentDto returns flat fields: taskTitle, taskPoints, taskIconEmoji, targetTime, etc.
    final parsedTask = json['task'] != null ? ChoreTaskModel.fromJson(json['task'] as Map<String, dynamic>) : null;

    final title = (json['taskTitle'] as String?) ??
        (json['title'] as String?) ??
        (parsedTask?.title) ??
        'Tugas';

    final points = (json['taskPoints'] as num?)?.toInt() ??
        (json['points'] as num?)?.toInt() ??
        (parsedTask?.points) ??
        0;

    final emoji = (json['taskIconEmoji'] as String?) ??
        (json['iconEmoji'] as String?) ??
        (parsedTask?.iconEmoji) ??
        '📋';

    final targetTime = (json['targetTime'] as String?) ?? (parsedTask?.targetTime);

    return TaskAssignmentModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      rawTitle: title,
      rawDescription: json['description'] as String? ?? parsedTask?.description,
      rawPoints: points,
      rawIconEmoji: emoji,
      targetTime: targetTime,
      task: parsedTask,
      assignedToId: json['assignedToId']?.toString() ?? '',
      assignedToName: json['assignedToName'] as String?,
      assignedToAvatarUrl: json['assignedToAvatarUrl'] as String?,
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status']?.toString() ?? 'Pending',
      submissionNote: json['submissionNote'] as String?,
      proofPhotoUrl: json['proofPhotoUrl'] as String?,
      completedAt: json['completedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
