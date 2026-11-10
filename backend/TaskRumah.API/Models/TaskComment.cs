namespace TaskRumah.API.Models;

public class TaskComment
{
    public Guid Id { get; set; }
    public Guid TaskAssignmentId { get; set; }
    public TaskAssignment TaskAssignment { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
