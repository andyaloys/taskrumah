import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Timer? _pollingTimer;

  static const String _channelId = 'familytask_reminders';
  static const String _channelName = 'FamilyTask Notifikasi & Pengingat';
  static const String _channelDescription = 'Pengingat ibadah sebelum waktu habis, tilawah, dan tugas harian';

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Request notification permissions for Android 13+
    final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      
      // Create notification channel
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidImpl.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void startPolling(ApiClient client) {
    _pollingTimer?.cancel();
    // Run immediately once
    checkAndTriggerReminders(client);
    // Poll every 60 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkAndTriggerReminders(client);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> checkAndTriggerReminders(ApiClient client) async {
    try {
      final token = await StorageService().getToken();
      if (token == null || token.isEmpty) return;

      final response = await client.dio.get('/notifications/reminders-summary');
      final data = response.data as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1. Check Unread Notifications from Backend (e.g. "Tugas Disetujui! 🎉", "Tugas Dikirim! 📋")
      final unreadList = (data['unreadNotifications'] as List<dynamic>?) ?? [];
      for (final n in unreadList) {
        final notifMap = n as Map<String, dynamic>;
        final notifId = notifMap['id']?.toString() ?? '';
        final title = notifMap['title']?.toString() ?? 'FamilyTask';
        final message = notifMap['message']?.toString() ?? '';

        final seenKey = 'notif_seen_$notifId';
        if (!prefs.getBool(seenKey).isTrue()) {
          final notifyId = notifId.hashCode.abs() % 100000;
          await showNotification(
            id: notifyId,
            title: title,
            body: message,
            payload: notifId,
          );
          await prefs.setBool(seenKey, true);
        }
      }

      // If user is child, evaluate worship and task reminders
      final role = data['role']?.toString();
      if (role != 'Child') return;

      final worship = data['worship'] as Map<String, dynamic>?;
      final worshipSetting = data['worshipSetting'] as Map<String, dynamic>?;
      final reminderMinutes = (worshipSetting?['reminderMinutesBeforeEnd'] as num?)?.toInt() ?? 30;
      final quranReminderTime = worshipSetting?['quranReminderTime']?.toString() ?? '19:00';

      // 2. Prayer Deadline Reminders (Before prayer window expires)
      if (worship != null) {
        _evaluatePrayerReminder(
          name: 'Subuh',
          status: worship['subuh'] as int? ?? 0,
          deadlineHour: 5,
          deadlineMinute: 40,
          now: now,
          reminderMinutes: reminderMinutes,
          todayStr: todayStr,
          prefs: prefs,
        );

        _evaluatePrayerReminder(
          name: 'Dzuhur',
          status: worship['dzuhur'] as int? ?? 0,
          deadlineHour: 15,
          deadlineMinute: 0,
          now: now,
          reminderMinutes: reminderMinutes,
          todayStr: todayStr,
          prefs: prefs,
        );

        _evaluatePrayerReminder(
          name: 'Ashar',
          status: worship['ashar'] as int? ?? 0,
          deadlineHour: 17,
          deadlineMinute: 55,
          now: now,
          reminderMinutes: reminderMinutes,
          todayStr: todayStr,
          prefs: prefs,
        );

        _evaluatePrayerReminder(
          name: 'Maghrib',
          status: worship['maghrib'] as int? ?? 0,
          deadlineHour: 19,
          deadlineMinute: 5,
          now: now,
          reminderMinutes: reminderMinutes,
          todayStr: todayStr,
          prefs: prefs,
        );

        _evaluatePrayerReminder(
          name: 'Isya',
          status: worship['isya'] as int? ?? 0,
          deadlineHour: 23,
          deadlineMinute: 0,
          now: now,
          reminderMinutes: reminderMinutes,
          todayStr: todayStr,
          prefs: prefs,
        );

        // 3. Tilawah / Ngaji Reminder
        final quranDone = worship['quranDone'] as bool? ?? false;
        if (!quranDone) {
          final parts = quranReminderTime.split(':');
          final qHour = int.tryParse(parts[0]) ?? 19;
          final qMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final quranDateTime = DateTime(now.year, now.month, now.day, qHour, qMinute);

          if (now.isAfter(quranDateTime)) {
            final key = 'quran_reminded_$todayStr';
            if (!prefs.getBool(key).isTrue()) {
              await showNotification(
                id: 10006,
                title: '📖 Pengingat Tilawah Qur\'an',
                body: 'Jangan lupa mengaji / tilawah Al-Qur\'an hari ini yaa untuk raih pahala dan poin! 🌟',
              );
              await prefs.setBool(key, true);
            }
          }
        }
      }

      // 4. Pending Tasks Reminders
      final pendingTasks = (data['pendingTasks'] as List<dynamic>?) ?? [];
      for (final t in pendingTasks) {
        final taskMap = t as Map<String, dynamic>;
        final taskId = taskMap['taskId']?.toString() ?? '';
        final title = taskMap['title']?.toString() ?? 'Tugas';
        final targetTime = taskMap['targetTime']?.toString();

        if (targetTime != null && targetTime.isNotEmpty) {
          final parts = targetTime.split(':');
          final tHour = int.tryParse(parts[0]) ?? 0;
          final tMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final targetDateTime = DateTime(now.year, now.month, now.day, tHour, tMinute);

          if (now.isAfter(targetDateTime)) {
            final key = 'task_reminded_${taskId}_$todayStr';
            if (!prefs.getBool(key).isTrue()) {
              await showNotification(
                id: 20000 + (taskId.hashCode.abs() % 10000),
                title: '⏰ Pengingat Tugas: $title',
                body: 'Waktu target untuk tugas "$title" sudah tiba. Yuk selesaikan sekarang! 💪',
              );
              await prefs.setBool(key, true);
            }
          }
        }
      }

      // General evening reminder (16:30 and 20:00) if pending tasks exist
      if (pendingTasks.isNotEmpty) {
        if (now.hour >= 16 && now.hour < 19) {
          final key = 'tasks_afternoon_reminded_$todayStr';
          if (!prefs.getBool(key).isTrue()) {
            await showNotification(
              id: 30001,
              title: '📋 ${pendingTasks.length} Tugas Belum Selesai',
              body: 'Sore Kak/Dek! Masih ada ${pendingTasks.length} tugas harian yang belum selesai. Yuk kerjakan sebelum malam! 🌟',
            );
            await prefs.setBool(key, true);
          }
        } else if (now.hour >= 20) {
          final key = 'tasks_night_reminded_$todayStr';
          if (!prefs.getBool(key).isTrue()) {
            await showNotification(
              id: 30002,
              title: '🌙 Cek Tugas Terakhir Hari Ini',
              body: 'Masih ada ${pendingTasks.length} tugas yang belum selesai hari ini. Jangan sampai terlambat yaa! ✨',
            );
            await prefs.setBool(key, true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking reminders: $e');
    }
  }

  void _evaluatePrayerReminder({
    required String name,
    required int status,
    required int deadlineHour,
    required int deadlineMinute,
    required DateTime now,
    required int reminderMinutes,
    required String todayStr,
    required SharedPreferences prefs,
  }) async {
    // If already done (status > 0), no reminder needed
    if (status > 0) return;

    final deadline = DateTime(now.year, now.month, now.day, deadlineHour, deadlineMinute);
    final reminderTime = deadline.subtract(Duration(minutes: reminderMinutes));

    // If current time is between reminderTime and deadline
    if (now.isAfter(reminderTime) && now.isBefore(deadline)) {
      final key = 'prayer_reminded_${name.toLowerCase()}_$todayStr';
      if (!prefs.getBool(key).isTrue()) {
        final diffMins = deadline.difference(now).inMinutes;
        final minutesText = diffMins > 0 ? '$diffMins menit' : 'beberapa saat';

        await showNotification(
          id: 10000 + deadlineHour,
          title: '🕌 Waktu Sholat $name Segera Habis',
          body: 'Waktu sholat $name tinggal $minutesText lagi lho! Yuk sholat sekarang jangan sampai terlewat (+poin)',
        );
        await prefs.setBool(key, true);
      }
    }
  }
}

extension BoolNullSafe on bool? {
  bool isTrue() => this == true;
}
