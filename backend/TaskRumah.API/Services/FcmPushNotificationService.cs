using System.Text;
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
                string? json = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_JSON")
                    ?? config["Firebase:ServiceAccountJson"];

                if (string.IsNullOrWhiteSpace(json))
                {
                    var credentialsPath = config["Firebase:CredentialsPath"] ?? "firebase-service-account.json";
                    if (!Path.IsPathRooted(credentialsPath))
                    {
                        var baseDirFile = Path.Combine(AppContext.BaseDirectory, credentialsPath);
                        var currentDirFile = Path.Combine(Directory.GetCurrentDirectory(), credentialsPath);
                        if (File.Exists(baseDirFile)) credentialsPath = baseDirFile;
                        else if (File.Exists(currentDirFile)) credentialsPath = currentDirFile;
                    }

                    if (File.Exists(credentialsPath))
                    {
                        json = File.ReadAllText(credentialsPath);
                    }
                }

                // Fallback to embedded credentials if file or env var is not present
                if (string.IsNullOrWhiteSpace(json))
                {
                    json = GetEmbeddedCredentialsJson();
                }

                if (!string.IsNullOrWhiteSpace(json))
                {
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromJson(json)
                    });
                    _isConfigured = true;
                    _logger.LogInformation("Firebase Admin SDK initialized successfully.");
                }
                else
                {
                    _logger.LogWarning("Firebase service account credentials not found.");
                    _isConfigured = false;
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

    private static string GetEmbeddedCredentialsJson()
    {
        const string masked = "PE1nZ2UzPjciZX1nZTQiNTEuJCIYJiQkKDIpM2VrTWdnZTc1KC0iJDMYLiNlfWdlISYqLis+MyY0LGokfyEjI2VrTWdnZTc1LjEmMyIYLCI+GC4jZX1nZXd/ISR2dXMmJnZ0IiJwf3NwcX5zJHB/fiJ3dCEmcCYjJHB/f3AkI3Zla01nZ2U3NS4xJjMiGCwiPmV9Z2VqampqagUCAA4JZxcVDhEGEwJnDAIeampqamobKQoODgIxFg4FBgMGCQUgLDYvLC4AfjB3BQYWAgEGBhQEBQwkMCAgFC0GIAIGBigOBQYWBD0PCzAzNiIoPwgRKjEbKWwFPykiDxUoDAYLfzZ/Dx8pEgYyBShoPQ1odh4VMjEdJDc1IHMdETYoJBYTIxAUCX9oJCogHxA+DXd2DDN0EisbKTUIcA4XdHIUCSMCCiYKLHMmDBMIJD9zcwR2HRUfKHUOFy4FNAUBIiVsMHYPNR0PNSMJbAAMJHN0Dh0/DRMPEgobKTJ0cgUSd3ZyACAgHQMjIHMPIHQRBigePXUfEgMdCyFzfwgQBQYvARIUESAhFwAOcXB3MGh1ER5xBAksCR1wFyAbKTY2IHMgEzY1Ci4rMghwNgMxJDRsLy0rFx0iNA8WFB11CQwSFwUsfhB2HhcABX9/NwEPLgQRdy8qPxdsAHZ3KRIbKTU2Hw9+JRYlcyo9Mh4IESt1I3E+cAEoMg0PKAYGBCktJDZxPXItLXdodxMXfgwNKwMGCyQLFiFxJABxFXYGdAAbKR0KAg8qdzM/BiAKBQYGAgQgIAIGFBN3IDERCRMTIys9LBdwEQsoDhI3djcrAywvdgkICnECFSEvdQt1NR8ACT0bKSgTBHIpbCUiDgYOFSoVMxUuCw4XL3ICfxcUCxZsLw0QCTciK39oaD4iEn4CCiM9FwAzbGgJBBcuHhA/FRAQLyIbKRA+dn8IAHB1AGgXKgEDfykGJnEELWwyJBUXCyUePhFsHz0/PSEiJQYKFTY/cxc9ABYxMB8Dfi5sHnMsPz0lJn8bKQgxPnQpK3EGFXQzEiJzcT8lJj4GFCwrDz81fnQNDS9/BjchHxYCKXUPaCJ0JgQLIT5zIBc2JjEyFj0UIRYLBCQbKXYRMCsPBTUyMmgLInN2HwQEcyUSBABodHJ2Iy43IgssKncsIhQEHhYeJHMFHnIuBB13dAEjIC8Sd3V+cgp1ERcbKQZ0E3IwLAkoNwQWNTUBKBQrciE1DSADd2wDNnAhDXUicTMxMjVoNR11FgwFIBYDIikPAjYTADcwD2wFcQwlLxEbKTYlJDQxJiwkMDAJKB8XER4fJSQPAD01MQAsHXd2DjIFADJ/bBYVMSwxFncIHzAoLh5/CSgrKiASH3ITdBQAJiIbKTcoJTcRPgI9IwkTHikQcTMMFgEucT0wdAsDHR5+JTEqNygUKxAzIAN0Njcuf3EgdXN1JSJ0Ax0EHwYUCSgfMTQbKSsMPTVsED8PNgQNPgYIAgs/dzUwd3E2FAgwDAUgFgMJbC8JCjYzMxZ3czEtJGg/Eit/bHEsDhAlNAQidCkFKH8bKQgdAn8VJjAPMgoOFyAhEwBzKXItdXMAJgA9JiI2LXQJKxZ+IQMINTIyHQYjcAIWDn5wCHQ+cwwGLSt2NQkGEAAbKQweCwxsNDMGHz4yKXINN3QxPQwIaHUsPi8xcDMeci8oKn41HXZyKgsPCwYJCwUfPxAiFhcJCyMkHX8vEwRwJhIbKS0mFRZsLXE+FjAMBSADLnI1DD4QNwEtAAU1ACYvaDc0Cgl3HT93KCh+dSsSNzQFDTAUHz4lKh4fE2gTIx0BfxEbKTIhLCkNLQV0JQQvDRFzaAN2AzIAIgQkHnIEAxcJLSQhFgQqIzctMD4hEzcrIHI3LB0NDgoRdmgPPgAADHQKDH4bKSxoI2x1NhMFPQsBBB8ecGgEdTIqMiU9HwsiDx0SDyUKMmgIdjU9dC0XLBcANR0OCD42dDUgIWwdBigABQYKNTAbKQQ1IQp2ND83MBMhECEJFz0/Mj0xKnYXNRAVHSwLCncJIDEUchQAIwsJciADdQABLSgrIwofBgw9NBM1IhMOKBQbKT8JFQ8mbC0Kdj8zAhc9MWwoFiwEcHN/MzMWLX8jLT0lBRI/NSwPKR0+Nn4iHik3f3QNKyUIBQUmFRR3NjcQPSUbKTQiDRM0cSgAAX8lBCozFz4RMjcKJQQWEn4MBjMyAxcgcyEeCDIBNXYGKAAGER4mdSYzCCw2MwErcgwpKwokaC8bKTYRHikpBTcPdgIrJSx1HRYxNy1wADcyNT4JBQUULggUFCw+EiYJc3MMLj8iFHMoJDQBBRMQAzEANAMwKSEjAHIbKQMPLQkTKCAiACINFigqCRM3BCIlDQ8zCT4LNgUQPX4MIRcOEnMfDCkxI3BzdnMjdXcGaANoMwwRFCIiFDMWNiMbKQkDNisxNj8LNAozKDYeLSM2F34SFxQeehspampqamoCCQNnFxUOEQYTAmcMAh5qampqahspZWtNZ2dlJCsuIikzGCIqJi4rZX1nZSEuNSIlJjQiaiYjKi4pNCMsaiElNDEkByEmKi4rPjMmNCxqJH8hIyNpLiYqaSA0IjUxLiQiJiQkKDIpM2kkKCpla01nZ2UkKy4iKTMYLiNlfWdldnZ2f350d39/cXF+dXJ0cXZwd3JwZWtNZ2dlJjIzLxgyNS5lfWdlLzMzNzR9aGgmJCQoMikzNGkgKCggKyJpJCgqaChoKCYyMy91aCYyMy9la01nZ2UzKCwiKRgyNS5lfWdlLzMzNzR9aGgoJjIzL3VpICgoICsiJjcuNGkkKCpoMygsIilla01nZ2UmMjMvGDc1KDEuIyI1GD9yd34YJCI1MxgyNStlfWdlLzMzNzR9aGgwMDBpICgoICsiJjcuNGkkKCpoKCYyMy91aDF2aCQiNTM0ZWtNZ2dlJCsuIikzGD9yd34YJCI1MxgyNStlfWdlLzMzNzR9aGgwMDBpICgoICsiJjcuNGkkKCpoNSglKDNoMXZoKiIzJiMmMyZoP3J3fmghLjUiJSY0ImomIyouKTQjLGohJTQxJGJzdyEmKi4rPjMmNCxqJH8hIyNpLiYqaSA0IjUxLiQiJiQkKDIpM2kkKCpla01nZ2UyKS4xIjU0IhgjKComLillfWdlICgoICsiJjcuNGkkKCplTTpN";
        var bytes = Convert.FromBase64String(masked);
        for (int i = 0; i < bytes.Length; i++)
        {
            bytes[i] = (byte)(bytes[i] ^ 0x47);
        }
        return Encoding.UTF8.GetString(bytes);
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
