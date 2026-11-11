using System;

namespace TaskRumah.API.Common;

public static class JakartaTime
{
    public static readonly TimeZoneInfo Zone = ResolveJakartaZone();

    private static TimeZoneInfo ResolveJakartaZone()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Asia/Jakarta");
        }
        catch
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
            }
            catch
            {
                return TimeZoneInfo.CreateCustomTimeZone("Asia/Jakarta", TimeSpan.FromHours(7), "WIB", "WIB");
            }
        }
    }

    /// <summary>
    /// Current DateTime in Jakarta (WIB, UTC+7).
    /// </summary>
    public static DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, Zone);

    /// <summary>
    /// Current calendar date in Jakarta (WIB) with time 00:00:00.
    /// </summary>
    public static DateTime Today => Now.Date;

    /// <summary>
    /// Current UTC instant with DateTimeKind.Utc explicitly set.
    /// </summary>
    public static DateTime UtcNow => DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Utc);

    /// <summary>
    /// Converts a Jakarta calendar date to the start of day in UTC (00:00:00 WIB -> 17:00:00 UTC previous day).
    /// </summary>
    public static DateTime StartOfDayUtc(DateTime jakartaDate)
    {
        var local = new DateTime(jakartaDate.Year, jakartaDate.Month, jakartaDate.Day, 0, 0, 0, DateTimeKind.Unspecified);
        var utc = TimeZoneInfo.ConvertTimeToUtc(local, Zone);
        return DateTime.SpecifyKind(utc, DateTimeKind.Utc);
    }

    /// <summary>
    /// Converts a Jakarta calendar date to the end of day in UTC (23:59:59 WIB -> 16:59:59 UTC same day).
    /// </summary>
    public static DateTime EndOfDayUtc(DateTime jakartaDate)
    {
        var local = new DateTime(jakartaDate.Year, jakartaDate.Month, jakartaDate.Day, 23, 59, 59, DateTimeKind.Unspecified);
        var utc = TimeZoneInfo.ConvertTimeToUtc(local, Zone);
        return DateTime.SpecifyKind(utc, DateTimeKind.Utc);
    }

    /// <summary>
    /// Converts any UTC DateTime to Jakarta time (WIB).
    /// </summary>
    public static DateTime ToJakarta(DateTime utcDateTime)
    {
        var utc = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
        return TimeZoneInfo.ConvertTimeFromUtc(utc, Zone);
    }

    /// <summary>
    /// Formats DateTime in WIB format: "dd MMM yyyy, HH:mm WIB".
    /// </summary>
    public static string FormatWib(DateTime? dt = null)
    {
        var target = dt.HasValue ? ToJakarta(dt.Value) : Now;
        return target.ToString("dd MMM yyyy, HH:mm") + " WIB";
    }
}
