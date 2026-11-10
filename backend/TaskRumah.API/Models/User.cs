namespace TaskRumah.API.Models;

public class User
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; }
    public string? AvatarUrl { get; set; }
    public int TotalPoints { get; set; }
    public int CurrentStreak { get; set; }
    public int LongestStreak { get; set; }
    public DateTime LastStreakDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<ChoreTask> AssignedTasks { get; set; } = new List<ChoreTask>();
    public ICollection<ChoreTask> CreatedTasks { get; set; } = new List<ChoreTask>();
    public ICollection<TaskAssignment> TaskAssignments { get; set; } = new List<TaskAssignment>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public ICollection<RewardRedemption> RewardRedemptions { get; set; } = new List<RewardRedemption>();
}

public enum UserRole { Admin, Child }
