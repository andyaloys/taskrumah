namespace TaskRumah.API.Models;

public class TaskAssignment
{
    public Guid Id { get; set; }
    public Guid TaskId { get; set; }
    public ChoreTask Task { get; set; } = null!;
    public Guid AssignedToId { get; set; }
    public User AssignedTo { get; set; } = null!;
    public DateTime DueDate { get; set; }
    public AssignmentStatus Status { get; set; } = AssignmentStatus.Pending;
    public string? ProofPhotoUrl { get; set; }
    public string? SubmissionNote { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedById { get; set; }
    public User? ReviewedBy { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }

    public ICollection<TaskComment> Comments { get; set; } = new List<TaskComment>();
}

public enum AssignmentStatus { Pending, Submitted, Approved, Rejected, Late }
