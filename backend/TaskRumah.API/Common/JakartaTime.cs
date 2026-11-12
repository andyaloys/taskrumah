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
    /// Current DateTime in Jakarta (WIB, UTC+7) as Unspecified kind (local time).
    /// </summary>
    public static DateTime Now
    {
        get
        {
            var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, Zone);
            return DateTime.SpecifyKind(local, DateTimeKind.Unspecified);
        }
    }

    /// <summary>
    /// Current calendar date in Jakarta (WIB) with time 00:00:00.
    /// </summary>
    public static DateTime Today => Now.Date;

    /// <summary>
    /// Start of day (00:00:00) for given Jakarta calendar date.
    /// </summary>
    public static DateTime StartOfDay(DateTime date) =>
        new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Unspecified);

    /// <summary>
    /// End of day (23:59:59) for given Jakarta calendar date.
    /// </summary>
    public static DateTime EndOfDay(DateTime date) =>
        new DateTime(date.Year, date.Month, date.Day, 23, 59, 59, DateTimeKind.Unspecified);

    // Aliases to guarantee all existing calls return clean Jakarta local time
    public static DateTime UtcNow => Now;
    public static DateTime StartOfDayUtc(DateTime jakartaDate) => StartOfDay(jakartaDate);
    public static DateTime EndOfDayUtc(DateTime jakartaDate) => EndOfDay(jakartaDate);

    public static string FormatWib(DateTime? dt = null)
    {
        var target = dt ?? Now;
        return target.ToString("dd MMM yyyy, HH:mm") + " WIB";
    }
}
