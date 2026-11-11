using System;

namespace TaskRumah.API.Models;

public enum PrayerStatus
{
    None = 0,    // Tidak Sholat (0 poin)
    Solo = 1,    // Sholat di Sekolah / Sendiri
    Mosque = 2   // Sholat Jamaah di Masjid
}

public class WorshipSetting
{
    public Guid Id { get; set; } = Guid.Parse("99999999-9999-9999-9999-999999999999");
    public int SoloPoints { get; set; } = 3;      // Sholat di Sekolah atau Sendiri
    public int MosquePoints { get; set; } = 5;    // Sholat Jamaah di Masjid
    public int QuranPoints { get; set; } = 5;     // Ngaji / Tilawah
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class DailyWorship
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public DateTime Date { get; set; } // Representing calendar date in UTC
    public PrayerStatus Subuh { get; set; } = PrayerStatus.None;
    public PrayerStatus Dzuhur { get; set; } = PrayerStatus.None;
    public PrayerStatus Ashar { get; set; } = PrayerStatus.None;
    public PrayerStatus Maghrib { get; set; } = PrayerStatus.None;
    public PrayerStatus Isya { get; set; } = PrayerStatus.None;
    public bool QuranDone { get; set; } = false;
    public string? QuranNote { get; set; }
    public int TotalPointsEarned { get; set; } = 0;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
