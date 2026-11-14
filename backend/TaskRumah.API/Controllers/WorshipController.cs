using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Common;
using TaskRumah.API.Data;
using TaskRumah.API.Models;

namespace TaskRumah.API.Controllers;

[ApiController]
[Route("api/worship")]
[Authorize]
public class WorshipController : ControllerBase
{
    private readonly AppDbContext _db;

    public WorshipController(AppDbContext db)
    {
        _db = db;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string CurrentRole => User.FindFirstValue(ClaimTypes.Role)!;

    [HttpGet("setting")]
    public async Task<IActionResult> GetSetting()
    {
        var setting = await _db.WorshipSettings.FirstOrDefaultAsync() 
            ?? new WorshipSetting();
        return Ok(setting);
    }

    [HttpPut("setting")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateSetting([FromBody] UpdateWorshipSettingRequest req)
    {
        var setting = await _db.WorshipSettings.FirstOrDefaultAsync();
        if (setting == null)
        {
            setting = new WorshipSetting();
            _db.WorshipSettings.Add(setting);
        }

        setting.SoloPoints = Math.Max(0, req.SoloPoints);
        setting.MosquePoints = Math.Max(0, req.MosquePoints);
        setting.QuranPoints = Math.Max(0, req.QuranPoints);
        setting.ReminderMinutesBeforeEnd = req.ReminderMinutesBeforeEnd > 0 ? req.ReminderMinutesBeforeEnd : 30;
        if (!string.IsNullOrWhiteSpace(req.QuranReminderTime))
            setting.QuranReminderTime = req.QuranReminderTime;
        setting.UpdatedAt = JakartaTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(setting);
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyWorship([FromQuery] string? date = null)
    {
        DateTime targetDate = (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var parsed))
            ? parsed.Date
            : JakartaTime.Today;

        var startUtc = JakartaTime.StartOfDayUtc(targetDate);
        var endUtc = JakartaTime.EndOfDayUtc(targetDate);

        var record = await _db.DailyWorships
            .FirstOrDefaultAsync(w => w.UserId == CurrentUserId && w.Date >= startUtc && w.Date <= endUtc);

        if (record == null)
        {
            record = new DailyWorship
            {
                Id = Guid.NewGuid(),
                UserId = CurrentUserId,
                Date = startUtc,
                Subuh = PrayerStatus.None,
                Dzuhur = PrayerStatus.None,
                Ashar = PrayerStatus.None,
                Maghrib = PrayerStatus.None,
                Isya = PrayerStatus.None,
                QuranDone = false,
                TotalPointsEarned = 0,
                CreatedAt = JakartaTime.UtcNow,
                UpdatedAt = JakartaTime.UtcNow
            };
            _db.DailyWorships.Add(record);
            await _db.SaveChangesAsync();
        }

        return Ok(record);
    }

    [HttpPost("save")]
    public async Task<IActionResult> SaveWorship([FromBody] SaveWorshipRequest req)
    {
        DateTime targetDate = (!string.IsNullOrEmpty(req.Date) && DateTime.TryParse(req.Date, out var parsed))
            ? parsed.Date
            : JakartaTime.Today;

        // Restriction: can only modify today and yesterday (H-1)
        var today = JakartaTime.Today;
        if (targetDate < today.AddDays(-1))
        {
            return BadRequest(new { message = "Data ibadah yang sudah lewat lebih dari 1 hari telah dikunci." });
        }

        var startUtc = JakartaTime.StartOfDayUtc(targetDate);
        var endUtc = JakartaTime.EndOfDayUtc(targetDate);

        var record = await _db.DailyWorships
            .FirstOrDefaultAsync(w => w.UserId == CurrentUserId && w.Date >= startUtc && w.Date <= endUtc);

        if (record == null)
        {
            record = new DailyWorship
            {
                Id = Guid.NewGuid(),
                UserId = CurrentUserId,
                Date = startUtc,
                CreatedAt = JakartaTime.UtcNow
            };
            _db.DailyWorships.Add(record);
        }

        var setting = await _db.WorshipSettings.FirstOrDefaultAsync() ?? new WorshipSetting();

        int CalculatePrayerPoints(PrayerStatus st) => st switch
        {
            PrayerStatus.Mosque => setting.MosquePoints,
            PrayerStatus.Solo => setting.SoloPoints,
            _ => 0
        };

        record.Subuh = req.Subuh;
        record.Dzuhur = req.Dzuhur;
        record.Ashar = req.Ashar;
        record.Maghrib = req.Maghrib;
        record.Isya = req.Isya;
        record.QuranDone = req.QuranDone;
        record.QuranNote = req.QuranNote;
        record.UpdatedAt = JakartaTime.UtcNow;

        int newPoints = CalculatePrayerPoints(record.Subuh)
                      + CalculatePrayerPoints(record.Dzuhur)
                      + CalculatePrayerPoints(record.Ashar)
                      + CalculatePrayerPoints(record.Maghrib)
                      + CalculatePrayerPoints(record.Isya)
                      + (record.QuranDone ? setting.QuranPoints : 0);

        int diff = newPoints - record.TotalPointsEarned;
        record.TotalPointsEarned = newPoints;

        var user = await _db.Users.FindAsync(CurrentUserId);
        if (user != null && diff != 0)
        {
            user.TotalPoints = Math.Max(0, user.TotalPoints + diff);
        }

        await _db.SaveChangesAsync();

        return Ok(new
        {
            record,
            userTotalPoints = user?.TotalPoints ?? 0,
            message = "Catatan ibadah berhasil disimpan!"
        });
    }

    [HttpGet("admin/summary")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminSummary([FromQuery] string? date = null)
    {
        DateTime targetDate = (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var parsed))
            ? parsed.Date
            : JakartaTime.Today;

        var startUtc = JakartaTime.StartOfDayUtc(targetDate);
        var endUtc = JakartaTime.EndOfDayUtc(targetDate);

        var children = await _db.Users
            .Where(u => u.Role == UserRole.Child && u.IsActive)
            .OrderBy(u => u.Name)
            .ToListAsync();

        var records = await _db.DailyWorships
            .Where(w => w.Date >= startUtc && w.Date <= endUtc)
            .ToListAsync();

        var result = children.Select(c =>
        {
            var r = records.FirstOrDefault(w => w.UserId == c.Id);
            return new
            {
                userId = c.Id,
                userName = c.Name,
                avatarUrl = c.AvatarUrl,
                totalPoints = c.TotalPoints,
                date = targetDate.ToString("yyyy-MM-dd"),
                subuh = r?.Subuh ?? PrayerStatus.None,
                dzuhur = r?.Dzuhur ?? PrayerStatus.None,
                ashar = r?.Ashar ?? PrayerStatus.None,
                maghrib = r?.Maghrib ?? PrayerStatus.None,
                isya = r?.Isya ?? PrayerStatus.None,
                quranDone = r?.QuranDone ?? false,
                quranNote = r?.QuranNote,
                pointsEarnedToday = r?.TotalPointsEarned ?? 0
            };
        });

        return Ok(result);
    }
}

public class UpdateWorshipSettingRequest
{
    public int SoloPoints { get; set; } = 3;
    public int MosquePoints { get; set; } = 5;
    public int QuranPoints { get; set; } = 5;
    public int ReminderMinutesBeforeEnd { get; set; } = 30;
    public string QuranReminderTime { get; set; } = "19:00";
}

public class SaveWorshipRequest
{
    public string? Date { get; set; }
    public PrayerStatus Subuh { get; set; }
    public PrayerStatus Dzuhur { get; set; }
    public PrayerStatus Ashar { get; set; }
    public PrayerStatus Maghrib { get; set; }
    public PrayerStatus Isya { get; set; }
    public bool QuranDone { get; set; }
    public string? QuranNote { get; set; }
}
