using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _db;

    public NotificationsController(AppDbContext db)
    {
        _db = db;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] bool? unreadOnly = false)
    {
        var query = _db.Notifications
            .Where(n => n.UserId == CurrentUserId)
            .AsQueryable();

        if (unreadOnly == true)
            query = query.Where(n => !n.IsRead);

        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new NotificationDto(n.Id, n.Title, n.Message, n.Type, n.IsRead, n.RelatedEntityId, n.CreatedAt))
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkRead(Guid id)
    {
        var notification = await _db.Notifications.FirstOrDefaultAsync(n => n.Id == id && n.UserId == CurrentUserId);
        if (notification == null) return NotFound();

        notification.IsRead = true;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        var notifications = await _db.Notifications
            .Where(n => n.UserId == CurrentUserId && !n.IsRead)
            .ToListAsync();

        foreach (var n in notifications)
            n.IsRead = true;

        await _db.SaveChangesAsync();
        return NoContent();
    }

        [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var count = await _db.Notifications.CountAsync(n => n.UserId == CurrentUserId && !n.IsRead);
        return Ok(new { count });
    }

    [HttpGet("reminders-summary")]
    public async Task<IActionResult> GetRemindersSummary()
    {
        var role = User.FindFirstValue(ClaimTypes.Role);
        var today = TaskRumah.API.Common.JakartaTime.Today;
        var startOfDay = TaskRumah.API.Common.JakartaTime.StartOfDayUtc(today);
        var endOfDay = TaskRumah.API.Common.JakartaTime.EndOfDayUtc(today);

        var unreadNotifications = await _db.Notifications
            .Where(n => n.UserId == CurrentUserId && !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .Take(10)
            .Select(n => new NotificationDto(n.Id, n.Title, n.Message, n.Type, n.IsRead, n.RelatedEntityId, n.CreatedAt))
            .ToListAsync();

        var worshipSetting = await _db.WorshipSettings.FirstOrDefaultAsync() ?? new TaskRumah.API.Models.WorshipSetting();

        object? worshipData = null;
        var pendingTasksList = new List<object>();

        if (role == "Child")
        {
            var todayWorship = await _db.DailyWorships
                .FirstOrDefaultAsync(w => w.UserId == CurrentUserId && w.Date >= startOfDay && w.Date <= endOfDay);

            worshipData = new
            {
                subuh = (int)(todayWorship?.Subuh ?? TaskRumah.API.Models.PrayerStatus.None),
                dzuhur = (int)(todayWorship?.Dzuhur ?? TaskRumah.API.Models.PrayerStatus.None),
                ashar = (int)(todayWorship?.Ashar ?? TaskRumah.API.Models.PrayerStatus.None),
                maghrib = (int)(todayWorship?.Maghrib ?? TaskRumah.API.Models.PrayerStatus.None),
                isya = (int)(todayWorship?.Isya ?? TaskRumah.API.Models.PrayerStatus.None),
                quranDone = todayWorship?.QuranDone ?? false,
                quranNote = todayWorship?.QuranNote
            };

            var assignments = await _db.TaskAssignments
                .Include(a => a.Task)
                .Where(a => a.AssignedToId == CurrentUserId && a.DueDate >= startOfDay && a.DueDate <= endOfDay && a.Status == TaskRumah.API.Models.AssignmentStatus.Pending)
                .ToListAsync();

            foreach (var a in assignments)
            {
                pendingTasksList.Add(new
                {
                    assignmentId = a.Id,
                    taskId = a.TaskId,
                    title = a.Task?.Title ?? "",
                    points = a.Task?.Points ?? 0,
                    iconEmoji = a.Task?.IconEmoji ?? "📋",
                    targetTime = a.Task?.TargetTime
                });
            }
        }

        return Ok(new
        {
            role,
            userId = CurrentUserId,
            todayDate = today.ToString("yyyy-MM-dd"),
            unreadNotifications,
            worshipSetting = new
            {
                reminderMinutesBeforeEnd = worshipSetting.ReminderMinutesBeforeEnd,
                quranReminderTime = worshipSetting.QuranReminderTime
            },
            worship = worshipData,
            pendingTasks = pendingTasksList
        });
    }
}
