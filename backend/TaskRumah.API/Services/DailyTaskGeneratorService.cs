using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.Models;

namespace TaskRumah.API.Services;

public class DailyTaskGeneratorService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<DailyTaskGeneratorService> _logger;

    public DailyTaskGeneratorService(IServiceProvider services, ILogger<DailyTaskGeneratorService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await RunDailyJobAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running initial daily task generation");
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            var nextMidnight = now.Date.AddDays(1);
            var delay = nextMidnight - now;

            await Task.Delay(delay, stoppingToken);

            if (!stoppingToken.IsCancellationRequested)
            {
                await RunDailyJobAsync();
            }
        }
    }

    private async Task RunDailyJobAsync()
    {
        _logger.LogInformation("Running daily task generator at {Time}", DateTime.UtcNow);

        using var scope = _services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var today = DateTime.UtcNow.Date;
        var yesterday = today.AddDays(-1);

        // Mark yesterday's uncompleted tasks as Late
        var overdueAssignments = await db.TaskAssignments
            .Where(a => a.DueDate.Date == yesterday && a.Status == AssignmentStatus.Pending)
            .Include(a => a.AssignedTo)
            .ToListAsync();

        foreach (var assignment in overdueAssignments)
        {
            assignment.Status = AssignmentStatus.Late;
            var notifSvc = scope.ServiceProvider.GetRequiredService<NotificationService>();
            await notifSvc.CreateAsync(
                assignment.AssignedToId,
                "Tugas Terlambat! ⏰",
                $"Kamu terlambat menyelesaikan tugas kemarin. Jangan terulang ya!",
                NotificationType.TaskDue,
                assignment.Id
            );
        }

        // Generate daily and specific days task assignments for today
        var dayNum = today.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)today.DayOfWeek;
        var activeTasks = await db.ChoreTasks
            .Where(t => t.IsActive && (t.TaskType == TaskType.Daily || t.TaskType == TaskType.SpecificDays))
            .ToListAsync();

        var tasksForToday = activeTasks.Where(t =>
            t.TaskType == TaskType.Daily ||
            (t.TaskType == TaskType.SpecificDays && !string.IsNullOrEmpty(t.DaysOfWeek) && t.DaysOfWeek.Split(',').Contains(dayNum.ToString()))
        ).ToList();

        foreach (var task in tasksForToday)
        {
            // Check if already generated for today
            var exists = await db.TaskAssignments
                .AnyAsync(a => a.TaskId == task.Id && a.DueDate.Date == today);

            if (!exists)
            {
                var assignees = new List<Guid>();

                if (task.AssignedToId.HasValue)
                {
                    assignees.Add(task.AssignedToId.Value);
                }
                else
                {
                    var children = await db.Users
                        .Where(u => u.Role == UserRole.Child && u.IsActive)
                        .Select(u => u.Id)
                        .ToListAsync();
                    assignees.AddRange(children);
                }

                foreach (var assigneeId in assignees)
                {
                    db.TaskAssignments.Add(new TaskAssignment
                    {
                        Id = Guid.NewGuid(),
                        TaskId = task.Id,
                        AssignedToId = assigneeId,
                        DueDate = today.AddDays(1).AddSeconds(-1), // end of today
                        Status = AssignmentStatus.Pending,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }
        }

        await db.SaveChangesAsync();

        // Update streaks
        await UpdateStreaksAsync(db, yesterday);
        _logger.LogInformation("Daily task generator completed.");
    }

    private async Task UpdateStreaksAsync(AppDbContext db, DateTime yesterday)
    {
        var children = await db.Users.Where(u => u.Role == UserRole.Child && u.IsActive).ToListAsync();
        foreach (var child in children)
        {
            var hadCompletedYesterday = await db.TaskAssignments
                .AnyAsync(a => a.AssignedToId == child.Id && a.DueDate.Date == yesterday && a.Status == AssignmentStatus.Approved);

            if (hadCompletedYesterday)
            {
                child.CurrentStreak++;
                child.LastStreakDate = yesterday;
                if (child.CurrentStreak > child.LongestStreak)
                    child.LongestStreak = child.CurrentStreak;
            }
            else
            {
                child.CurrentStreak = 0;
            }
        }
        await db.SaveChangesAsync();
    }
}
