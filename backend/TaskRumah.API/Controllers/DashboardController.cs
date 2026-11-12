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
[Route("api/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly TaskScheduleService _scheduleService;

    public DashboardController(AppDbContext db, TaskScheduleService scheduleService)
    {
        _db = db;
        _scheduleService = scheduleService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminDashboard([FromQuery] int weekOffset = 0, [FromQuery] string? date = null)
    {
        var today = JakartaTime.Today;
        DateTime targetDate = (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var parsedDate))
            ? parsedDate.Date
            : today.AddDays(weekOffset * 7);

        int diff = (7 + (int)targetDate.DayOfWeek - (int)DayOfWeek.Monday) % 7;
        var startOfWeek = targetDate.AddDays(-diff);
        var endOfWeek = startOfWeek.AddDays(6);
        var startOfWeekUtc = JakartaTime.StartOfDayUtc(startOfWeek);
        var endOfWeekUtc = JakartaTime.EndOfDayUtc(endOfWeek);

        var children = await _db.Users
            .Where(u => u.Role == UserRole.Child && u.IsActive)
            .ToListAsync();

        List<TaskAssignmentDto> displayAssignmentDtos;
        if (weekOffset == 0 || !string.IsNullOrEmpty(date))
        {
            displayAssignmentDtos = await _scheduleService.GetAssignmentsForDateAsync(targetDate);
        }
        else
        {
            var rawAssignments = await _db.TaskAssignments
                .Include(a => a.Task)
                .Include(a => a.AssignedTo)
                .Include(a => a.ReviewedBy)
                .Include(a => a.Comments)
                .Where(a => a.DueDate >= startOfWeekUtc && a.DueDate <= endOfWeekUtc)
                .OrderByDescending(a => a.DueDate)
                .ToListAsync();
            displayAssignmentDtos = rawAssignments.Select(MapAssignmentToDto).ToList();
        }

        var weeklyAssignments = await _db.TaskAssignments
            .Include(a => a.Task)
            .Where(a => a.Status == AssignmentStatus.Approved && a.DueDate >= startOfWeekUtc && a.DueDate <= endOfWeekUtc)
            .ToListAsync();

        var weeklyWorships = await _db.DailyWorships
            .Where(w => w.Date >= startOfWeekUtc && w.Date <= endOfWeekUtc)
            .ToListAsync();

        var childProgressList = children.Select(child =>
        {
            var childTasks = displayAssignmentDtos.Where(a => a.AssignedToId == child.Id).ToList();
            var taskPoints = weeklyAssignments.Where(a => a.AssignedToId == child.Id).Sum(a => a.Task?.Points ?? 0);
            var worshipPoints = weeklyWorships.Where(w => w.UserId == child.Id).Sum(w => w.TotalPointsEarned);
            var weeklyPoints = taskPoints + worshipPoints;
            return new ChildProgressDto(
                child.Id,
                child.Name,
                child.AvatarUrl,
                child.TotalPoints,
                child.CurrentStreak,
                childTasks.Count,
                childTasks.Count(a => a.Status == AssignmentStatus.Approved),
                childTasks.Count(a => a.Status == AssignmentStatus.Pending),
                childTasks,
                weeklyPoints
            );
        }).ToList();

        var pendingReviews = displayAssignmentDtos
            .Where(a => a.Status == AssignmentStatus.Submitted)
            .ToList();

        return Ok(new AdminDashboardDto(
            childProgressList,
            pendingReviews,
            displayAssignmentDtos.Count,
            displayAssignmentDtos.Count(a => a.Status == AssignmentStatus.Approved),
            startOfWeek,
            endOfWeek,
            weekOffset,
            targetDate
        ));
    }

    [HttpGet("child/{userId}")]
    public async Task<IActionResult> GetChildDashboard(Guid userId, [FromQuery] int weekOffset = 0, [FromQuery] string? date = null)
    {
        var currentUserId = CurrentUserId;
        var currentRole = User.FindFirstValue(ClaimTypes.Role);

        if (currentRole == "Child" && currentUserId != userId)
            return Forbid();

        var user = await _db.Users.FindAsync(userId);
        if (user == null) return NotFound();

        var today = JakartaTime.Today;
        DateTime targetDate = (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var parsedDate))
            ? parsedDate.Date
            : today.AddDays(weekOffset * 7);

        int diff = (7 + (int)targetDate.DayOfWeek - (int)DayOfWeek.Monday) % 7;
        var startOfWeek = targetDate.AddDays(-diff);
        var endOfWeek = startOfWeek.AddDays(6);
        var startOfWeekUtc = JakartaTime.StartOfDayUtc(startOfWeek);
        var endOfWeekUtc = JakartaTime.EndOfDayUtc(endOfWeek);

        List<TaskAssignmentDto> displayAssignmentDtos;
        if (weekOffset == 0 || !string.IsNullOrEmpty(date))
        {
            displayAssignmentDtos = await _scheduleService.GetAssignmentsForDateAsync(targetDate, userId);
        }
        else
        {
            var rawAssignments = await _db.TaskAssignments
                .Include(a => a.Task)
                .Include(a => a.AssignedTo)
                .Include(a => a.ReviewedBy)
                .Include(a => a.Comments)
                .Where(a => a.AssignedToId == userId && a.DueDate >= startOfWeekUtc && a.DueDate <= endOfWeekUtc)
                .OrderByDescending(a => a.DueDate)
                .ToListAsync();
            displayAssignmentDtos = rawAssignments.Select(MapAssignmentToDto).ToList();
        }

        var tomorrow = today.AddDays(1);
        var tomorrowTasks = await _scheduleService.GetAssignmentsForDateAsync(tomorrow, userId);

        var weeklyTaskPoints = await _db.TaskAssignments
            .Where(a => a.AssignedToId == userId && a.Status == AssignmentStatus.Approved && a.DueDate >= startOfWeekUtc && a.DueDate <= endOfWeekUtc)
            .Select(a => (int?)a.Task.Points)
            .SumAsync() ?? 0;

        var weeklyWorshipPoints = await _db.DailyWorships
            .Where(w => w.UserId == userId && w.Date >= startOfWeekUtc && w.Date <= endOfWeekUtc)
            .Select(w => (int?)w.TotalPointsEarned)
            .SumAsync() ?? 0;

        var weeklyPoints = weeklyTaskPoints + weeklyWorshipPoints;

        var recentNotifications = await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .Take(5)
            .Select(n => new NotificationDto(n.Id, n.Title, n.Message, n.Type, n.IsRead, n.RelatedEntityId, n.CreatedAt))
            .ToListAsync();

        return Ok(new ChildDashboardDto(
            user.Id, user.Name, user.AvatarUrl,
            user.TotalPoints, user.CurrentStreak, user.LongestStreak,
            displayAssignmentDtos.Count,
            displayAssignmentDtos.Count(a => a.Status == AssignmentStatus.Approved),
            displayAssignmentDtos,
            tomorrowTasks,
            recentNotifications,
            weeklyPoints,
            startOfWeek,
            endOfWeek,
            weekOffset,
            targetDate
        ));
    }

    private static TaskAssignmentDto MapAssignmentToDto(TaskAssignment a) => new(
        a.Id, a.TaskId, a.Task?.Title ?? "", a.Task?.IconEmoji ?? "✅", a.Task?.Points ?? 0,
        a.AssignedToId, a.AssignedTo?.Name ?? "", a.AssignedTo?.AvatarUrl,
        a.DueDate, a.Status, a.ProofPhotoUrl, a.SubmissionNote,
        a.CompletedAt, a.ReviewedAt, a.ReviewedBy?.Name, a.RejectionReason,
        a.CreatedAt, a.Comments?.Count ?? 0);
}
