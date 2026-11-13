class ChoreTaskModel {
  final String id;
  final String title;
  final String? description;
  final int points;
  final String? iconEmoji;
  final bool isDaily;

  ChoreTaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.points,
    this.iconEmoji,
    required this.isDaily,
  });

  factory ChoreTaskModel.fromJson(Map<String, dynamic> json) {
    return ChoreTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Tugas',
      description: json['description'] as String?,
      points: json['points'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '⭐',
      isDaily: json['isDaily'] as bool? ?? false,
    );
  }
}

class TaskAssignmentModel {
  final String id;
  final String taskId;
  final ChoreTaskModel? task;
  final String assignedToId;
  final String dueDate;
  final String status; // 'Pending', 'Submitted', 'Approved', 'Rejected'
  final String? submissionNote;
  final String? proofPhotoUrl;
  final String? completedAt;
  final String? rejectionReason;

  TaskAssignmentModel({
    required this.id,
    required this.taskId,
    this.task,
    required this.assignedToId,
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

  String get title => task?.title ?? 'Tugas';
  String get description => task?.description ?? '';
  int get points => task?.points ?? 0;
  String get iconEmoji => task?.iconEmoji ?? '📋';

  factory TaskAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TaskAssignmentModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      task: json['task'] != null ? ChoreTaskModel.fromJson(json['task'] as Map<String, dynamic>) : null,
      assignedToId: json['assignedToId']?.toString() ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      status: json['status']?.toString() ?? 'Pending',
      submissionNote: json['submissionNote'] as String?,
      proofPhotoUrl: json['proofPhotoUrl'] as String?,
      completedAt: json['completedAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
