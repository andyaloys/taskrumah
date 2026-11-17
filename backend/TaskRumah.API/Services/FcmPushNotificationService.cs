using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace TaskRumah.API.Services;

public class FcmPushNotificationService
{
    private readonly ILogger<FcmPushNotificationService> _logger;
    private readonly bool _isConfigured;

    public FcmPushNotificationService(IConfiguration config, ILogger<FcmPushNotificationService> logger)
    {
        _logger = logger;

        try
        {
            if (FirebaseApp.DefaultInstance == null)
            {
                var envJson = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_JSON")
                    ?? config["Firebase:ServiceAccountJson"];

                if (!string.IsNullOrWhiteSpace(envJson))
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromJson(envJson)
                    });
                    _isConfigured = true;
                    _logger.LogInformation("Firebase Admin SDK initialized successfully from environment variable");
                }
                else
                {
                    var credentialsPath = config["Firebase:CredentialsPath"] ?? "firebase-service-account.json";
                    if (!Path.IsPathRooted(credentialsPath))
                    {
                        var baseDirFile = Path.Combine(AppContext.BaseDirectory, credentialsPath);
                        var currentDirFile = Path.Combine(Directory.GetCurrentDirectory(), credentialsPath);
                        if (File.Exists(baseDirFile))
                            credentialsPath = baseDirFile;
                        else if (File.Exists(currentDirFile))
                            credentialsPath = currentDirFile;
                        else
                            credentialsPath = baseDirFile;
                    }

                    if (File.Exists(credentialsPath))
                    {
                        FirebaseApp.Create(new AppOptions
                        {
                            Credential = GoogleCredential.FromFile(credentialsPath)
                        });
                        _isConfigured = true;
                        _logger.LogInformation("Firebase Admin SDK initialized successfully from {Path}", credentialsPath);
                    }
                    else
                    {
                        _logger.LogWarning("Firebase service account credentials not found at {Path}. Push notifications to closed devices will be queued until file is added.", credentialsPath);
                        _isConfigured = false;
                    }
                }
            }
            else
            {
                _isConfigured = true;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Firebase Admin SDK");
            _isConfigured = false;
        }
    }

    public async Task SendPushAsync(string fcmToken, string title, string body, Dictionary<string, string>? data = null)
    {
        if (!_isConfigured || string.IsNullOrWhiteSpace(fcmToken)) return;

        try
        {
            var message = new Message
            {
                Token = fcmToken,
                Notification = new FirebaseAdmin.Messaging.Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>(),
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = "familytask_reminders",
                        Sound = "default",
                        Priority = NotificationPriority.HIGH
                    }
                }
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation("Successfully sent FCM message: {Response}", response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending FCM message to token {Token}", fcmToken);
        }
    }

    public async Task SendToMultipleAsync(IEnumerable<string> fcmTokens, string title, string body, Dictionary<string, string>? data = null)
    {
        foreach (var token in fcmTokens.Where(t => !string.IsNullOrWhiteSpace(t)))
        {
            await SendPushAsync(token, title, body, data);
        }
    }
}
