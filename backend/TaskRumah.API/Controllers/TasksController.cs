using TaskRumah.API.Common;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.DTOs;
using TaskRumah.API.Models;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/tasks")]
[Authorize]
public class TasksController : ControllerBase
{
    private readonly AppDbContext _db;

    public TasksController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] bool? activeOnly = true)
    {
        var query = _db.ChoreTasks
            .Include(t => t.AssignedTo)
            .Include(t => t.CreatedBy)
            .AsQueryable();

        if (activeOnly == true)
            query = query.Where(t => t.IsActive);

        var tasks = await query
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new ChoreTaskDto(
                t.Id, t.Title, t.Description, t.TaskType, t.DaysOfWeek,
                t.AssignedToId, t.AssignedTo != null ? t.AssignedTo.Name : null,
                t.CreatedById, t.CreatedBy.Name, t.Points, t.IconEmoji, t.IsActive, t.CreatedAt))
            .ToListAsync();

        return Ok(tasks);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var task = await _db.ChoreTasks
            .Include(t => t.AssignedTo)
            .Include(t => t.CreatedBy)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null) return NotFound();

        return Ok(new ChoreTaskDto(
            task.Id, task.Title, task.Description, task.TaskType, task.DaysOfWeek,
            task.AssignedToId, task.AssignedTo?.Name,
            task.CreatedById, task.CreatedBy.Name, task.Points, task.IconEmoji, task.IsActive, task.CreatedAt));
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create([FromBody] CreateTaskRequest req)
    {
        var createdById = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var task = new ChoreTask
        {
            Id = Guid.NewGuid(),
            Title = req.Title,
            Description = req.Description,
            TaskType = req.TaskType,
            DaysOfWeek = req.DaysOfWeek,
            AssignedToId = req.AssignedToId,
            CreatedById = createdById,
            Points = req.Points,
            IconEmoji = req.IconEmoji,
            IsActive = true,
            CreatedAt = JakartaTime.UtcNow
        };

        _db.ChoreTasks.Add(task);
        await _db.SaveChangesAsync();

        // Create assignment for newly created task
        await CreateTodayAssignmentsAsync(task, req.DueDate);

        await _db.Entry(task).Reference(t => t.CreatedBy).LoadAsync();
        if (task.AssignedToId.HasValue)
            await _db.Entry(task).Reference(t => t.AssignedTo).LoadAsync();

        return CreatedAtAction(nameof(GetById), new { id = task.Id },
            new ChoreTaskDto(task.Id, task.Title, task.Description, task.TaskType, task.DaysOfWeek,
                task.AssignedToId, task.AssignedTo?.Name,
                task.CreatedById, task.CreatedBy.Name, task.Points, task.IconEmoji, task.IsActive, task.CreatedAt));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateTaskRequest req)
    {
        var task = await _db.ChoreTasks
            .Include(t => t.AssignedTo)
            .Include(t => t.CreatedBy)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (task == null) return NotFound();

        if (req.Title != null) task.Title = req.Title;
        if (req.Description != null) task.Description = req.Description;
        if (req.TaskType.HasValue) task.TaskType = req.TaskType.Value;
        if (req.DaysOfWeek != null) task.DaysOfWeek = req.DaysOfWeek;
        task.AssignedToId = req.AssignedToId;
        if (req.Points.HasValue) task.Points = req.Points.Value;
        if (req.IconEmoji != null) task.IconEmoji = req.IconEmoji;
        if (req.IsActive.HasValue) task.IsActive = req.IsActive.Value;

        await _db.SaveChangesAsync();

        // Sync today's pending assignments if schedule, assignee, or active status changed
        await SyncTodayAssignmentsForTaskAsync(task);

        await _db.Entry(task).Reference(t => t.CreatedBy).LoadAsync();
        if (task.AssignedToId.HasValue)
        {
            await _db.Entry(task).Reference(t => t.AssignedTo).LoadAsync();
        }
        else
        {
            task.AssignedTo = null;
        }

        return Ok(new ChoreTaskDto(task.Id, task.Title, task.Description, task.TaskType, task.DaysOfWeek,
            task.AssignedToId, task.AssignedTo?.Name,
            task.CreatedById, task.CreatedBy.Name, task.Points, task.IconEmoji, task.IsActive, task.CreatedAt));
    }

    [HttpPost("{id}/assign")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AssignTask(Guid id, [FromBody] AssignTaskRequest req)
    {
        var task = await _db.ChoreTasks.FindAsync(id);
        if (task == null || !task.IsActive) return NotFound();

        var today = JakartaTime.Today;
        var targetDate = req.DueDate.HasValue
            ? req.DueDate.Value.Date
            : today;
        var assignees = new List<Guid>();

        if (req.AssignedToId.HasValue)
        {
            assignees.Add(req.AssignedToId.Value);
        }
        else if (task.AssignedToId.HasValue)
        {
            assignees.Add(task.AssignedToId.Value);
        }
        else
        {
            var children = await _db.Users
                .Where(u => u.Role == UserRole.Child && u.IsActive)
                .Select(u => u.Id)
                .ToListAsync();
            assignees.AddRange(children);
        }

        var dueDate = JakartaTime.EndOfDayUtc(targetDate);
        foreach (var childId in assignees)
        {
            _db.TaskAssignments.Add(new TaskAssignment
            {
                Id = Guid.NewGuid(),
                TaskId = task.Id,
                AssignedToId = childId,
                DueDate = dueDate,
                Status = AssignmentStatus.Pending,
                CreatedAt = JakartaTime.UtcNow
            });
        }

        await _db.SaveChangesAsync();
        return Ok(new { message = $"Tugas '{task.Title}' berhasil ditugaskan untuk {targetDate:dd MMM yyyy}!" });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var task = await _db.ChoreTasks.FindAsync(id);
        if (task == null) return NotFound();

        task.IsActive = false;
        await _db.SaveChangesAsync();

        await SyncTodayAssignmentsForTaskAsync(task);
        return NoContent();
    }

    private async Task SyncTodayAssignmentsForTaskAsync(ChoreTask task)
    {
        var today = JakartaTime.Today;
        var startOfDay = JakartaTime.StartOfDayUtc(today);
        var endOfDay = JakartaTime.EndOfDayUtc(today);
        var dayNum = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;

        var todayPending = await _db.TaskAssignments
            .Where(a => a.TaskId == task.Id && a.DueDate >= startOfDay && a.DueDate <= endOfDay && a.Status == AssignmentStatus.Pending)
            .ToListAsync();

        if (!task.IsActive)
        {
            if (todayPending.Any())
            {
                _db.TaskAssignments.RemoveRange(todayPending);
                await _db.SaveChangesAsync();
            }
            return;
        }

        bool isScheduledForToday = false;
        if (task.TaskType == TaskType.Daily)
        {
            isScheduledForToday = true;
        }
        else if (task.TaskType == TaskType.SpecificDays)
        {
            isScheduledForToday = !string.IsNullOrEmpty(task.DaysOfWeek) && task.DaysOfWeek.Split(',').Contains(dayNum.ToString());
        }

        if (!isScheduledForToday)
        {
            if (todayPending.Any())
            {
                _db.TaskAssignments.RemoveRange(todayPending);
                await _db.SaveChangesAsync();
            }
            return;
        }

        var targetAssignees = new List<Guid>();
        if (task.AssignedToId.HasValue)
        {
            targetAssignees.Add(task.AssignedToId.Value);
        }
        else
        {
            var children = await _db.Users
                .Where(u => u.Role == UserRole.Child && u.IsActive)
                .Select(u => u.Id)
                .ToListAsync();
            targetAssignees.AddRange(children);
        }

        var toRemove = todayPending.Where(a => !targetAssignees.Contains(a.AssignedToId)).ToList();
        if (toRemove.Any())
        {
            _db.TaskAssignments.RemoveRange(toRemove);
        }

        var existingChildIds = await _db.TaskAssignments
            .Where(a => a.TaskId == task.Id && a.DueDate >= startOfDay && a.DueDate <= endOfDay)
            .Select(a => a.AssignedToId)
            .ToListAsync();

        var dueDate = JakartaTime.EndOfDayUtc(today);
        foreach (var childId in targetAssignees)
        {
            if (!existingChildIds.Contains(childId))
            {
                _db.TaskAssignments.Add(new TaskAssignment
                {
                    Id = Guid.NewGuid(),
                    TaskId = task.Id,
                    AssignedToId = childId,
                    DueDate = dueDate,
                    Status = AssignmentStatus.Pending,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        await _db.SaveChangesAsync();
    }

    private async Task CreateTodayAssignmentsAsync(ChoreTask task, DateTime? targetDate = null)
    {
        var today = JakartaTime.Today;
        var dayNum = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;

        if (task.TaskType == TaskType.SpecificDays)
        {
            if (string.IsNullOrEmpty(task.DaysOfWeek) || !task.DaysOfWeek.Split(',').Contains(dayNum.ToString()))
                return;
        }

        DateTime target = targetDate.HasValue
            ? targetDate.Value.Date
            : today;
        var dueDate = JakartaTime.EndOfDayUtc(target);
        var assignees = new List<Guid>();

        if (task.AssignedToId.HasValue)
        {
            assignees.Add(task.AssignedToId.Value);
        }
        else
        {
            var children = await _db.Users
                .Where(u => u.Role == UserRole.Child && u.IsActive)
                .Select(u => u.Id)
                .ToListAsync();
            assignees.AddRange(children);
        }

        foreach (var assigneeId in assignees)
        {
            _db.TaskAssignments.Add(new TaskAssignment
            {
                Id = Guid.NewGuid(),
                TaskId = task.Id,
                AssignedToId = assigneeId,
                DueDate = dueDate,
                Status = AssignmentStatus.Pending,
                CreatedAt = JakartaTime.UtcNow
            });
        }

        await _db.SaveChangesAsync();
    }
}
