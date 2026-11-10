namespace TaskRumah.API.Models;

public class RewardRedemption
{
    public Guid Id { get; set; }
    public Guid RewardId { get; set; }
    public Reward Reward { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public RedemptionStatus Status { get; set; } = RedemptionStatus.Pending;
    public DateTime RequestedAt { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public Guid? ProcessedById { get; set; }
    public User? ProcessedBy { get; set; }
    public string? Notes { get; set; }
}

public enum RedemptionStatus { Pending, Approved, Rejected }
