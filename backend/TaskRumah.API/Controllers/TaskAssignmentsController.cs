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
[Route("api/task-assignments")]
[Authorize]
public class TaskAssignmentsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly FileStorageService _fileStorage;
    private readonly NotificationService _notificationService;
    private readonly TaskScheduleService _scheduleService;

    public TaskAssignmentsController(
        AppDbContext db,
        FileStorageService fileStorage,
        NotificationService notificationService,
        TaskScheduleService scheduleService)
    {
        _db = db;
        _fileStorage = fileStorage;
        _notificationService = notificationService;
        _scheduleService = scheduleService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string CurrentRole => User.FindFirstValue(ClaimTypes.Role)!;

    [HttpGet("schedule")]
    public async Task<IActionResult> GetSchedule(
        [FromQuery] DateTime? date,
        [FromQuery] Guid? userId)
    {
        var targetDate = date.HasValue ? date.Value.Date : JakartaTime.Today;
        Guid? targetUserId = userId;

        if (CurrentRole == "Child")
            targetUserId = CurrentUserId;

        var assignments = await _scheduleService.GetAssignmentsForDateAsync(targetDate, targetUserId);
        return Ok(assignments);
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] Guid? userId,
        [FromQuery] AssignmentStatus? status,
        [FromQuery] DateTime? date)
    {
        var query = _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .Include(a => a.ReviewedBy)
            .Include(a => a.Comments)
            .AsQueryable();

        if (CurrentRole == "Child")
            query = query.Where(a => a.AssignedToId == CurrentUserId && (a.Task.IsActive || a.Status != AssignmentStatus.Pending));
        else if (userId.HasValue)
            query = query.Where(a => a.AssignedToId == userId.Value && (a.Task.IsActive || a.Status != AssignmentStatus.Pending));

        if (status.HasValue)
            query = query.Where(a => a.Status == status.Value);

        if (date.HasValue)
        {
            var startUtc = JakartaTime.StartOfDayUtc(date.Value);
            var endUtc = JakartaTime.EndOfDayUtc(date.Value);
            query = query.Where(a => a.DueDate >= startUtc && a.DueDate <= endUtc);
        }

        var assignments = await query
            .OrderByDescending(a => a.DueDate)
            .ToListAsync();

        return Ok(assignments.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var assignment = await _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .Include(a => a.ReviewedBy)
            .Include(a => a.Comments)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (assignment == null)
        {
            // Fallback: Check if 'id' is a ChoreTaskId for a child accessing today's task
            if (CurrentRole == "Child")
            {
                var choreTask = await _db.ChoreTasks.FirstOrDefaultAsync(t => t.Id == id);
                if (choreTask != null)
                {
                    var today = JakartaTime.Today;
                    var startOfDay = JakartaTime.StartOfDayUtc(today);
                    var endOfDay = JakartaTime.EndOfDayUtc(today);

                    assignment = await _db.TaskAssignments
                        .Include(a => a.Task)
                        .Include(a => a.AssignedTo)
                        .Include(a => a.ReviewedBy)
                        .Include(a => a.Comments)
                        .FirstOrDefaultAsync(a => a.TaskId == choreTask.Id && a.AssignedToId == CurrentUserId && a.DueDate >= startOfDay && a.DueDate <= endOfDay);

                    if (assignment == null)
                    {
                        var newAssignment = new TaskAssignment
                        {
                            Id = Guid.NewGuid(),
                            TaskId = choreTask.Id,
                            AssignedToId = CurrentUserId,
                            DueDate = endOfDay,
                            Status = AssignmentStatus.Pending,
                            CreatedAt = JakartaTime.UtcNow
                        };
                        _db.TaskAssignments.Add(newAssignment);
                        await _db.SaveChangesAsync();

                        assignment = await _db.TaskAssignments
                            .Include(a => a.Task)
                            .Include(a => a.AssignedTo)
                            .Include(a => a.ReviewedBy)
                            .Include(a => a.Comments)
                            .FirstAsync(a => a.Id == newAssignment.Id);
                    }

                    return Ok(MapToDto(assignment));
                }
            }

            return NotFound();
        }

        if (CurrentRole == "Child" && assignment.AssignedToId != CurrentUserId)
            return Forbid();

        return Ok(MapToDto(assignment));
    }

    [HttpPost("{id}/submit")]
    public async Task<IActionResult> Submit(Guid id, [FromForm] SubmitTaskRequest req, IFormFile? photo)
    {
        var assignment = await _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (assignment == null)
        {
            // Fallback: Check if 'id' is a ChoreTaskId
            if (CurrentRole == "Child")
            {
                var choreTask = await _db.ChoreTasks.FirstOrDefaultAsync(t => t.Id == id);
                if (choreTask != null)
                {
                    var todayDate = JakartaTime.Today;
                    var startOfDay = JakartaTime.StartOfDayUtc(todayDate);
                    var endOfDay = JakartaTime.EndOfDayUtc(todayDate);

                    assignment = await _db.TaskAssignments
                        .Include(a => a.Task)
                        .Include(a => a.AssignedTo)
                        .FirstOrDefaultAsync(a => a.TaskId == choreTask.Id && a.AssignedToId == CurrentUserId && a.DueDate >= startOfDay && a.DueDate <= endOfDay);

                    if (assignment == null)
                    {
                        var newAssignment = new TaskAssignment
                        {
                            Id = Guid.NewGuid(),
                            TaskId = choreTask.Id,
                            AssignedToId = CurrentUserId,
                            DueDate = endOfDay,
                            Status = AssignmentStatus.Pending,
                            CreatedAt = JakartaTime.UtcNow
                        };
                        _db.TaskAssignments.Add(newAssignment);
                        await _db.SaveChangesAsync();

                        assignment = await _db.TaskAssignments
                            .Include(a => a.Task)
                            .Include(a => a.AssignedTo)
                            .FirstAsync(a => a.Id == newAssignment.Id);
                    }
                }
            }
        }

        if (assignment == null) return NotFound();

        if (CurrentRole == "Child" && assignment.AssignedToId != CurrentUserId)
            return Forbid();

        var today = JakartaTime.Today;
        var minAllowedDate = JakartaTime.StartOfDayUtc(today.AddDays(-1));
        if (assignment.DueDate < minAllowedDate)
            return BadRequest(new { message = "Data tugas yang sudah lewat lebih dari 1 hari telah dikunci dan tidak dapat diubah lagi." });

        if (assignment.Status != AssignmentStatus.Pending && assignment.Status != AssignmentStatus.Rejected && assignment.Status != AssignmentStatus.Late)
            return BadRequest(new { message = "Tugas tidak dalam status yang bisa dikirim" });

        if (photo != null)
            assignment.ProofPhotoUrl = await _fileStorage.SaveFileAsync(photo, "uploads/proofs");

        assignment.SubmissionNote = req.SubmissionNote;
        assignment.Status = AssignmentStatus.Submitted;
        assignment.CompletedAt = JakartaTime.UtcNow;

        await _db.SaveChangesAsync();

        var timeStr = JakartaTime.FormatWib();
        await _notificationService.CreateForAdminsAsync(
            $"Tugas Dikirim! 📋",
            $"{assignment.AssignedTo.Name} telah mengajukan bukti tugas '{assignment.Task.Title}' pada {timeStr}",
            NotificationType.TaskSubmitted,
            assignment.Id
        );

        return Ok(MapToDto(assignment));
    }

    [HttpPost("{id}/approve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Approve(Guid id)
    {
        var assignment = await _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (assignment == null) return NotFound();

        var today = JakartaTime.Today;
        var minAllowedDate = JakartaTime.StartOfDayUtc(today.AddDays(-1));
        if (assignment.DueDate < minAllowedDate)
            return BadRequest(new { message = "Data tugas yang sudah lewat lebih dari 1 hari telah dikunci dan tidak dapat diubah lagi." });

        if (assignment.Status == AssignmentStatus.Approved)
            return BadRequest(new { message = "Tugas sudah disetujui sebelumnya" });

        assignment.Status = AssignmentStatus.Approved;
        assignment.ReviewedAt = JakartaTime.UtcNow;
        assignment.ReviewedById = CurrentUserId;

        // Add points to user
        var user = await _db.Users.FindAsync(assignment.AssignedToId);
        if (user != null)
        {
            user.TotalPoints += assignment.Task.Points;

            // Update streak
            if (user.LastStreakDate.Date == today.AddDays(-1))
            {
                user.CurrentStreak++;
                user.LastStreakDate = JakartaTime.StartOfDayUtc(today);
                if (user.CurrentStreak > user.LongestStreak)
                    user.LongestStreak = user.CurrentStreak;
            }
            else if (user.LastStreakDate.Date != today)
            {
                user.CurrentStreak = 1;
                user.LastStreakDate = JakartaTime.StartOfDayUtc(today);
            }
        }

        await _db.SaveChangesAsync();

        var timeStr = JakartaTime.FormatWib();
        await _notificationService.CreateAsync(
            assignment.AssignedToId,
            "Tugas Disetujui! 🎉",
            $"Tugas '{assignment.Task.Title}' kamu telah disetujui pada {timeStr}! (+{assignment.Task.Points} poin)",
            NotificationType.TaskApproved,
            assignment.Id
        );

        return Ok(MapToDto(assignment));
    }

    [HttpPut("{id}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateAssignmentStatusRequest req)
    {
        var assignment = await _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (assignment == null) return NotFound();

        var today = JakartaTime.Today;
        var minAllowedDate = JakartaTime.StartOfDayUtc(today.AddDays(-1));
        if (assignment.DueDate < minAllowedDate)
            return BadRequest(new { message = "Data tugas yang sudah lewat lebih dari 1 hari telah dikunci dan tidak dapat diubah lagi." });

        var oldStatus = assignment.Status;
        var newStatus = req.Status;

        if (oldStatus == newStatus)
            return Ok(MapToDto(assignment));

        var user = await _db.Users.FindAsync(assignment.AssignedToId);
        var timeStr = JakartaTime.FormatWib();

        if (newStatus == AssignmentStatus.Approved && oldStatus != AssignmentStatus.Approved)
        {
            if (user != null) user.TotalPoints += assignment.Task.Points;
            assignment.ReviewedAt = JakartaTime.UtcNow;
            assignment.ReviewedById = CurrentUserId;

            await _notificationService.CreateAsync(
                assignment.AssignedToId,
                "Tugas Disetujui! 🎉",
                $"Tugas '{assignment.Task.Title}' kamu telah disetujui pada {timeStr}! (+{assignment.Task.Points} poin)",
                NotificationType.TaskApproved,
                assignment.Id
            );
        }
        else if (oldStatus == AssignmentStatus.Approved && newStatus != AssignmentStatus.Approved)
        {
            if (user != null) user.TotalPoints = Math.Max(0, user.TotalPoints - assignment.Task.Points);
        }
        else if (newStatus == AssignmentStatus.Rejected && oldStatus != AssignmentStatus.Rejected)
        {
            await _notificationService.CreateAsync(
                assignment.AssignedToId,
                "Tugas Ditolak 😢",
                $"Tugas '{assignment.Task.Title}' ditolak pada {timeStr}. Catatan: {req.Reason ?? "Belum memenuhi kriteria"}",
                NotificationType.TaskRejected,
                assignment.Id
            );
        }

        assignment.Status = newStatus;
        if (!string.IsNullOrEmpty(req.Reason))
            assignment.RejectionReason = req.Reason;

        await _db.SaveChangesAsync();
        return Ok(MapToDto(assignment));
    }

    [HttpPost("{id}/reject")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Reject(Guid id, [FromBody] RejectTaskRequest req)
    {
        var assignment = await _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .FirstOrDefaultAsync(a => a.Id == id);

        if (assignment == null) return NotFound();

        var today = JakartaTime.Today;
        var minAllowedDate = JakartaTime.StartOfDayUtc(today.AddDays(-1));
        if (assignment.DueDate < minAllowedDate)
            return BadRequest(new { message = "Data tugas yang sudah lewat lebih dari 1 hari telah dikunci dan tidak dapat diubah lagi." });

        if (assignment.Status != AssignmentStatus.Submitted)
            return BadRequest(new { message = "Tugas harus dalam status Submitted untuk ditolak" });

        assignment.Status = AssignmentStatus.Rejected;
        assignment.ReviewedAt = JakartaTime.UtcNow;
        assignment.ReviewedById = CurrentUserId;
        assignment.RejectionReason = req.RejectionReason;

        await _db.SaveChangesAsync();

        var timeStr = JakartaTime.FormatWib();
        await _notificationService.CreateAsync(
            assignment.AssignedToId,
            "Tugas Ditolak 😢",
            $"Tugas '{assignment.Task.Title}' ditolak pada {timeStr}. Catatan: {req.RejectionReason}",
            NotificationType.TaskRejected,
            assignment.Id
        );

        return Ok(MapToDto(assignment));
    }

    [HttpGet("{id}/comments")]
    public async Task<IActionResult> GetComments(Guid id)
    {
        var comments = await _db.TaskComments
            .Include(c => c.User)
            .Where(c => c.TaskAssignmentId == id)
            .OrderBy(c => c.CreatedAt)
            .ToListAsync();

        return Ok(comments.Select(c => new TaskCommentDto(
            c.Id, c.TaskAssignmentId, c.UserId, c.User.Name, c.User.AvatarUrl,
            c.User.Role, c.Comment, c.CreatedAt)));
    }

    [HttpPost("{id}/comments")]
    public async Task<IActionResult> AddComment(Guid id, [FromBody] AddCommentRequest req)
    {
        var assignment = await _db.TaskAssignments.FindAsync(id);
        if (assignment == null) return NotFound();

        if (CurrentRole == "Child" && assignment.AssignedToId != CurrentUserId)
            return Forbid();

        var comment = new TaskComment
        {
            Id = Guid.NewGuid(),
            TaskAssignmentId = id,
            UserId = CurrentUserId,
            Comment = req.Comment,
            CreatedAt = JakartaTime.UtcNow
        };

        _db.TaskComments.Add(comment);
        await _db.SaveChangesAsync();
        await _db.Entry(comment).Reference(c => c.User).LoadAsync();

        return Ok(new TaskCommentDto(
            comment.Id, comment.TaskAssignmentId, comment.UserId, comment.User.Name,
            comment.User.AvatarUrl, comment.User.Role, comment.Comment, comment.CreatedAt));
    }

    private static TaskAssignmentDto MapToDto(TaskAssignment a) => new(
        a.Id, a.TaskId, a.Task?.Title ?? "", a.Task?.IconEmoji ?? "✅", a.Task?.Points ?? 0,
        a.AssignedToId, a.AssignedTo?.Name ?? "", a.AssignedTo?.AvatarUrl,
        a.DueDate, a.Status, a.ProofPhotoUrl, a.SubmissionNote,
        a.CompletedAt, a.ReviewedAt, a.ReviewedBy?.Name, a.RejectionReason,
        a.CreatedAt, a.Comments?.Count ?? 0);
}
