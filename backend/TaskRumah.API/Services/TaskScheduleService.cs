using TaskRumah.API.Common;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Models;

namespace TaskRumah.API.Services;

public class TaskScheduleService
{
    private readonly AppDbContext _db;

    public TaskScheduleService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<TaskAssignmentDto>> GetAssignmentsForDateAsync(DateTime targetDate, Guid? childId = null)
    {
        var startOfDay = JakartaTime.StartOfDayUtc(targetDate);
        var endOfDay = JakartaTime.EndOfDayUtc(targetDate);
        var today = JakartaTime.Today;

        // 1. Fetch existing assignments from DB for that date
        var query = _db.TaskAssignments
            .Include(a => a.Task)
            .Include(a => a.AssignedTo)
            .Include(a => a.ReviewedBy)
            .Include(a => a.Comments)
            .Where(a => a.DueDate >= startOfDay && a.DueDate <= endOfDay && (a.Task.IsActive || a.Status != AssignmentStatus.Pending));

        if (childId.HasValue)
        {
            query = query.Where(a => a.AssignedToId == childId.Value);
        }

        var existingAssignments = await query.ToListAsync();
        var result = existingAssignments.Select(MapAssignmentToDto).ToList();

        // 2. If target date is today or in the future, project active recurring tasks
        if (targetDate.Date >= today)
        {
            var dayNum = targetDate.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)targetDate.DayOfWeek;

            var activeTasks = await _db.ChoreTasks
                .Include(t => t.AssignedTo)
                .Where(t => t.IsActive && (t.TaskType == TaskType.Daily || t.TaskType == TaskType.SpecificDays))
                .ToListAsync();

            var tasksForDay = activeTasks.Where(t =>
                t.TaskType == TaskType.Daily ||
                (t.TaskType == TaskType.SpecificDays && !string.IsNullOrEmpty(t.DaysOfWeek) && t.DaysOfWeek.Split(',').Contains(dayNum.ToString()))
            ).ToList();

            var childrenQuery = _db.Users
                .Where(u => u.Role == UserRole.Child && u.IsActive);

            if (childId.HasValue)
            {
                childrenQuery = childrenQuery.Where(u => u.Id == childId.Value);
            }

            var children = await childrenQuery.ToListAsync();

            var dueDate = endOfDay;

            foreach (var task in tasksForDay)
            {
                var targetChildren = task.AssignedToId.HasValue
                    ? children.Where(c => c.Id == task.AssignedToId.Value).ToList()
                    : children;

                foreach (var child in targetChildren)
                {
                    // Check if already in result for this task and this child
                    if (!result.Any(r => r.TaskId == task.Id && r.AssignedToId == child.Id))
                    {
                        result.Add(new TaskAssignmentDto(
                            Guid.Empty,
                            task.Id,
                            task.Title,
                            task.IconEmoji ?? "📋",
                            task.Points,
                            child.Id,
                            child.Name,
                            child.AvatarUrl,
                            dueDate,
                            AssignmentStatus.Pending,
                            null,
                            null,
                            null,
                            null,
                            null,
                            null,
                            startOfDay,
                            0
                        ));
                    }
                }
            }
        }

        return result.OrderBy(a => a.AssignedToName).ThenBy(a => a.TaskTitle).ToList();
    }

    public static TaskAssignmentDto MapAssignmentToDto(TaskAssignment a) => new(
        a.Id,
        a.TaskId,
        a.Task?.Title ?? "",
        a.Task?.IconEmoji ?? "✅",
        a.Task?.Points ?? 0,
        a.AssignedToId,
        a.AssignedTo?.Name ?? "",
        a.AssignedTo?.AvatarUrl,
        a.DueDate,
        a.Status,
        a.ProofPhotoUrl,
        a.SubmissionNote,
        a.CompletedAt,
        a.ReviewedAt,
        a.ReviewedBy?.Name,
        a.RejectionReason,
        a.CreatedAt,
        a.Comments?.Count ?? 0
    );
}
