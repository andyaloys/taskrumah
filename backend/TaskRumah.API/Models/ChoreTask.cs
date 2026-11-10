namespace TaskRumah.API.Models;

public class ChoreTask
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TaskType TaskType { get; set; }
    public string? DaysOfWeek { get; set; } // e.g. "1,3,5" (1=Mon..7=Sun)
    public Guid? AssignedToId { get; set; }
    public User? AssignedTo { get; set; }
    public Guid CreatedById { get; set; }
    public User CreatedBy { get; set; } = null!;
    public int Points { get; set; }
    public string IconEmoji { get; set; } = "✅";
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public ICollection<TaskAssignment> Assignments { get; set; } = new List<TaskAssignment>();
}

public enum TaskType { Daily = 0, OneTime = 1, SpecificDays = 2 }
