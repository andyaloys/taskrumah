using TaskRumah.API.Models;

namespace TaskRumah.API.DTOs;

public record LoginRequest(string Email, string Password);

public record LoginResponse(
    string Token,
    Guid UserId,
    string Name,
    string Email,
    UserRole Role,
    string? AvatarUrl,
    int TotalPoints,
    int CurrentStreak
);

public record UserDto(
    Guid Id,
    string Name,
    string Email,
    UserRole Role,
    string? AvatarUrl,
    int TotalPoints,
    int CurrentStreak,
    int LongestStreak,
    bool IsActive
);

public record UpdateUserRequest(
    string? Name,
    string? AvatarUrl,
    string? Password = null
);

public record CreateUserRequest(
    string Name,
    string Email,
    string Password,
    UserRole Role = UserRole.Child
);

public record CreateTaskRequest(
    string Title,
    string? Description,
    TaskType TaskType,
    string? DaysOfWeek,
    Guid? AssignedToId,
    int Points,
    string IconEmoji,
    DateTime? DueDate,
    string? TargetTime = null
);

public record UpdateTaskRequest(
    string? Title,
    string? Description,
    TaskType? TaskType,
    string? DaysOfWeek,
    Guid? AssignedToId,
    int? Points,
    string? IconEmoji,
    bool? IsActive,
    string? TargetTime = null
);

public record AssignTaskRequest(
    Guid? AssignedToId,
    DateTime? DueDate
);

public record UpdateAssignmentStatusRequest(
    AssignmentStatus Status,
    string? Reason
);

public record ChoreTaskDto(
    Guid Id,
    string Title,
    string? Description,
    TaskType TaskType,
    string? DaysOfWeek,
    Guid? AssignedToId,
    string? AssignedToName,
    Guid CreatedById,
    string CreatedByName,
    int Points,
    string IconEmoji,
    bool IsActive,
    DateTime CreatedAt,
    string? TargetTime = null
);

public record TaskAssignmentDto(
    Guid Id,
    Guid TaskId,
    string TaskTitle,
    string TaskIconEmoji,
    int TaskPoints,
    Guid AssignedToId,
    string AssignedToName,
    string? AssignedToAvatarUrl,
    DateTime DueDate,
    AssignmentStatus Status,
    string? ProofPhotoUrl,
    string? SubmissionNote,
    DateTime? CompletedAt,
    DateTime? ReviewedAt,
    string? ReviewedByName,
    string? RejectionReason,
    DateTime CreatedAt,
    int CommentCount,
    string? TargetTime = null
);

public record SubmitTaskRequest(
    string? SubmissionNote
);

public record RejectTaskRequest(string RejectionReason);

public record TaskCommentDto(
    Guid Id,
    Guid TaskAssignmentId,
    Guid UserId,
    string UserName,
    string? UserAvatarUrl,
    UserRole UserRole,
    string Comment,
    DateTime CreatedAt
);

public record AddCommentRequest(string Comment);

public record RewardDto(
    Guid Id,
    string Title,
    string? Description,
    int PointsRequired,
    string IconEmoji,
    bool IsActive,
    DateTime CreatedAt
);

public record CreateRewardRequest(
    string Title,
    string? Description,
    int PointsRequired,
    string IconEmoji
);

public record UpdateRewardRequest(
    string? Title,
    string? Description,
    int? PointsRequired,
    string? IconEmoji,
    bool? IsActive
);

public record RewardRedemptionDto(
    Guid Id,
    Guid RewardId,
    string RewardTitle,
    string RewardIconEmoji,
    int PointsRequired,
    Guid UserId,
    string UserName,
    RedemptionStatus Status,
    DateTime RequestedAt,
    DateTime? ProcessedAt,
    string? ProcessedByName,
    string? Notes
);

public record ProcessRedemptionRequest(
    RedemptionStatus Status,
    string? Notes
);

public record NotificationDto(
    Guid Id,
    string Title,
    string Message,
    NotificationType Type,
    bool IsRead,
    Guid? RelatedEntityId,
    DateTime CreatedAt
);

public record AdminDashboardDto(
    List<ChildProgressDto> Children,
    List<TaskAssignmentDto> PendingReviews,
    int TotalTasksToday,
    int TotalApprovedToday,
    DateTime WeekStart,
    DateTime WeekEnd,
    int WeekOffset,
    DateTime TargetDate
);

public record ChildProgressDto(
    Guid UserId,
    string Name,
    string? AvatarUrl,
    int TotalPoints,
    int CurrentStreak,
    int TasksToday,
    int TasksCompleted,
    int TasksPending,
    List<TaskAssignmentDto> TodayTasks,
    int WeeklyPoints
);

public record ChildDashboardDto(
    Guid UserId,
    string Name,
    string? AvatarUrl,
    int TotalPoints,
    int CurrentStreak,
    int LongestStreak,
    int TasksToday,
    int TasksCompleted,
    List<TaskAssignmentDto> TodayTasks,
    List<TaskAssignmentDto> TomorrowTasks,
    List<NotificationDto> RecentNotifications,
    int WeeklyPoints,
    DateTime WeekStart,
    DateTime WeekEnd,
    int WeekOffset,
    DateTime TargetDate
);
