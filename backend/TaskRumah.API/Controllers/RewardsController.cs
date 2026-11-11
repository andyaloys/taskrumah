using TaskRumah.API.Common;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Models;
using TaskRumah.API.Services;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/rewards")]
[Authorize]
public class RewardsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly NotificationService _notificationService;

    public RewardsController(AppDbContext db, NotificationService notificationService)
    {
        _db = db;
        _notificationService = notificationService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string CurrentRole => User.FindFirstValue(ClaimTypes.Role)!;

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var rewards = await _db.Rewards
            .Where(r => r.IsActive)
            .OrderBy(r => r.PointsRequired)
            .Select(r => new RewardDto(r.Id, r.Title, r.Description, r.PointsRequired, r.IconEmoji, r.IsActive, r.CreatedAt))
            .ToListAsync();
        return Ok(rewards);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateRewardRequest req)
    {
        var reward = new Reward
        {
            Id = Guid.NewGuid(),
            Title = req.Title,
            Description = req.Description,
            PointsRequired = req.PointsRequired,
            IconEmoji = req.IconEmoji,
            CreatedById = CurrentUserId,
            IsActive = true,
            CreatedAt = JakartaTime.UtcNow
        };
        _db.Rewards.Add(reward);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAll), new RewardDto(reward.Id, reward.Title, reward.Description, reward.PointsRequired, reward.IconEmoji, reward.IsActive, reward.CreatedAt));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateRewardRequest req)
    {
        var reward = await _db.Rewards.FindAsync(id);
        if (reward == null) return NotFound();

        if (req.Title != null) reward.Title = req.Title;
        if (req.Description != null) reward.Description = req.Description;
        if (req.PointsRequired.HasValue) reward.PointsRequired = req.PointsRequired.Value;
        if (req.IconEmoji != null) reward.IconEmoji = req.IconEmoji;
        if (req.IsActive.HasValue) reward.IsActive = req.IsActive.Value;

        await _db.SaveChangesAsync();
        return Ok(new RewardDto(reward.Id, reward.Title, reward.Description, reward.PointsRequired, reward.IconEmoji, reward.IsActive, reward.CreatedAt));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var reward = await _db.Rewards.FindAsync(id);
        if (reward == null) return NotFound();
        reward.IsActive = false;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{id}/redeem")]
    [Authorize(Roles = "Child")]
    public async Task<IActionResult> Redeem(Guid id)
    {
        var reward = await _db.Rewards.FindAsync(id);
        if (reward == null || !reward.IsActive) return NotFound();

        var user = await _db.Users.FindAsync(CurrentUserId);
        if (user == null) return NotFound();

        if (user.TotalPoints < reward.PointsRequired)
            return BadRequest(new { message = $"Poin tidak cukup. Butuh {reward.PointsRequired}, kamu punya {user.TotalPoints}" });

        var redemption = new RewardRedemption
        {
            Id = Guid.NewGuid(),
            RewardId = id,
            UserId = CurrentUserId,
            Status = RedemptionStatus.Pending,
            RequestedAt = JakartaTime.UtcNow
        };
        _db.RewardRedemptions.Add(redemption);
        await _db.SaveChangesAsync();

        await _notificationService.CreateForAdminsAsync(
            "Permintaan Hadiah Baru! 🎁",
            $"{user.Name} ingin menukarkan hadiah '{reward.Title}'",
            NotificationType.RewardApproved,
            redemption.Id
        );

        return Ok(new { message = "Permintaan hadiah berhasil dikirim!" });
    }

    [HttpGet("redemptions")]
    public async Task<IActionResult> GetRedemptions([FromQuery] Guid? userId, [FromQuery] RedemptionStatus? status)
    {
        var query = _db.RewardRedemptions
            .Include(r => r.Reward)
            .Include(r => r.User)
            .Include(r => r.ProcessedBy)
            .AsQueryable();

        if (CurrentRole == "Child")
            query = query.Where(r => r.UserId == CurrentUserId);
        else if (userId.HasValue)
            query = query.Where(r => r.UserId == userId.Value);

        if (status.HasValue)
            query = query.Where(r => r.Status == status.Value);

        var items = await query.OrderByDescending(r => r.RequestedAt).ToListAsync();

        return Ok(items.Select(r => new RewardRedemptionDto(
            r.Id, r.RewardId, r.Reward.Title, r.Reward.IconEmoji, r.Reward.PointsRequired,
            r.UserId, r.User.Name, r.Status, r.RequestedAt, r.ProcessedAt,
            r.ProcessedBy?.Name, r.Notes)));
    }

    [HttpPut("redemptions/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ProcessRedemption(Guid id, [FromBody] ProcessRedemptionRequest req)
    {
        var redemption = await _db.RewardRedemptions
            .Include(r => r.Reward)
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (redemption == null) return NotFound();
        if (redemption.Status != RedemptionStatus.Pending)
            return BadRequest(new { message = "Permintaan sudah diproses" });

        redemption.Status = req.Status;
        redemption.ProcessedAt = JakartaTime.UtcNow;
        redemption.ProcessedById = CurrentUserId;
        redemption.Notes = req.Notes;

        if (req.Status == RedemptionStatus.Approved)
        {
            var user = await _db.Users.FindAsync(redemption.UserId);
            if (user != null)
                user.TotalPoints -= redemption.Reward.PointsRequired;

            await _notificationService.CreateAsync(
                redemption.UserId,
                "Hadiah Disetujui! 🎉",
                $"Permintaan hadiahmu '{redemption.Reward.Title}' telah disetujui!",
                NotificationType.RewardApproved,
                redemption.Id
            );
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = "Berhasil diproses" });
    }
}
