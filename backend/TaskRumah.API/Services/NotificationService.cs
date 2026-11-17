using TaskRumah.API.Common;
using Microsoft.EntityFrameworkCore;
using TaskRumah.API.Data;
using TaskRumah.API.Models;

namespace TaskRumah.API.Services;

public class NotificationService
{
    private readonly AppDbContext _db;
    private readonly FcmPushNotificationService _fcm;

    public NotificationService(AppDbContext db, FcmPushNotificationService fcm)
    {
        _db = db;
        _fcm = fcm;
    }

    public async Task CreateAsync(Guid userId, string title, string message, NotificationType type, Guid? relatedEntityId = null)
    {
        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = title,
            Message = message,
            Type = type,
            IsRead = false,
            RelatedEntityId = relatedEntityId,
            CreatedAt = JakartaTime.UtcNow
        };
        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync();

        var user = await _db.Users.FindAsync(userId);
        if (user != null && !string.IsNullOrWhiteSpace(user.FcmToken))
        {
            var data = new Dictionary<string, string>
            {
                { "notificationId", notification.Id.ToString() },
                { "type", type.ToString() }
            };
            await _fcm.SendPushAsync(user.FcmToken, title, message, data);
        }
    }

    public async Task CreateForAdminsAsync(string title, string message, NotificationType type, Guid? relatedEntityId = null)
    {
        var admins = await _db.Users.Where(u => u.Role == UserRole.Admin && u.IsActive).ToListAsync();
        var fcmTokens = new List<string>();

        foreach (var admin in admins)
        {
            _db.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = admin.Id,
                Title = title,
                Message = message,
                Type = type,
                IsRead = false,
                RelatedEntityId = relatedEntityId,
                CreatedAt = JakartaTime.UtcNow
            });

            if (!string.IsNullOrWhiteSpace(admin.FcmToken))
            {
                fcmTokens.Add(admin.FcmToken);
            }
        }
        await _db.SaveChangesAsync();

        if (fcmTokens.Count > 0)
        {
            await _fcm.SendToMultipleAsync(fcmTokens, title, message);
        }
    }
}
