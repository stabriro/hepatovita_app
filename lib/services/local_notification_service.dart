import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static const _kBadgeCountKey = 'notification_badge_count_v1';

  static final LocalNotificationService instance = LocalNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _timezoneInitialized = false;

  Future<void> init() async {
    _ensureTimezoneInitialized();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
    );

    await _plugin.initialize(settings);

    await clearBadgeCount();

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _ensureTimezoneInitialized() {
    if (_timezoneInitialized) {
      return;
    }
    tz.initializeTimeZones();
    _timezoneInitialized = true;
  }

  Future<void> showCriticalAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    final badgeCount = await _incrementBadgeCount();

    final android = AndroidNotificationDetails(
      'critical_lab_alerts',
      'Critical Lab Alerts',
      channelDescription: 'High-severity biomarker risk alerts',
      importance: Importance.max,
      priority: Priority.high,
      number: badgeCount,
      channelShowBadge: true,
    );
    final darwin = DarwinNotificationDetails(badgeNumber: badgeCount);
    const linux = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> showSmartReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    final badgeCount = await _incrementBadgeCount();

    final android = AndroidNotificationDetails(
      'smart_health_reminders',
      'Smart Health Reminders',
      channelDescription: 'Adaptive reminders based on daily adherence',
      importance: Importance.high,
      priority: Priority.high,
      number: badgeCount,
      channelShowBadge: true,
    );
    final darwin = DarwinNotificationDetails(badgeNumber: badgeCount);
    const linux = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleSmartReminderAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    _ensureTimezoneInitialized();

    final badgeCount = await _nextBadgeCountHint();

    final android = AndroidNotificationDetails(
      'smart_health_reminders',
      'Smart Health Reminders',
      channelDescription: 'Adaptive reminders based on daily adherence',
      importance: Importance.high,
      priority: Priority.high,
      number: badgeCount,
      channelShowBadge: true,
    );
    final darwin = DarwinNotificationDetails(badgeNumber: badgeCount);
    const linux = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    final zonedDate = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      zonedDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    _ensureTimezoneInitialized();

    final badgeCount = await _nextBadgeCountHint();

    final android = AndroidNotificationDetails(
      'medication_daily_reminders',
      'Medication Daily Reminders',
      channelDescription: 'Scheduled reminders for medication doses',
      importance: Importance.high,
      priority: Priority.high,
      number: badgeCount,
      channelShowBadge: true,
    );
    final darwin = DarwinNotificationDetails(badgeNumber: badgeCount);
    const linux = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    final scheduledDate = _nextInstanceOfTime(hour: hour, minute: minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelScheduledNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> clearBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBadgeCountKey, 0);
  }

  Future<int> _incrementBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final nextCount = (prefs.getInt(_kBadgeCountKey) ?? 0) + 1;
    await prefs.setInt(_kBadgeCountKey, nextCount);

    return nextCount;
  }

  Future<int> _nextBadgeCountHint() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_kBadgeCountKey) ?? 0) + 1;
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
