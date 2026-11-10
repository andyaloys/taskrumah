namespace TaskRumah.API.Models;

public class Reward
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int PointsRequired { get; set; }
    public string IconEmoji { get; set; } = "🎁";
    public Guid CreatedById { get; set; }
    public User CreatedBy { get; set; } = null!;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public ICollection<RewardRedemption> Redemptions { get; set; } = new List<RewardRedemption>();
}
