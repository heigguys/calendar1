import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_item.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'calendar_reminders';
  static const String _channelName = '日程提醒';
  static const String _channelDescription = '本地日程提醒通知';

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);
    await _requestPermissions();
    await _configureTimezone();
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final canScheduleExact = await android?.canScheduleExactNotifications();
    if (canScheduleExact == false) {
      await android?.requestExactAlarmsPermission();
    }
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      debugPrint('Timezone init fallback to local: $e');
    }
  }

  Future<void> scheduleOrUpdateReminder(ScheduleItem item) async {
    if (kIsWeb) {
      return;
    }

    await cancelReminder(item.id);

    if (item.reminderTime == null) {
      return;
    }

    final reminderTime = item.reminderTime!;
    if (!reminderTime.isAfter(DateTime.now())) {
      return;
    }

    final notificationId = _notificationId(item.id);
    final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact = await android?.canScheduleExactNotifications();
    final scheduleMode = canScheduleExact == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      notificationId,
      item.title,
      _notificationBody(item),
      tzReminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      payload: item.id.toString(),
    );
  }

  Future<void> cancelReminder(int scheduleId) async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancel(_notificationId(scheduleId));
  }

  String _notificationBody(ScheduleItem item) {
    if (item.isAllDay) {
      return '全天日程：${item.category}';
    }
    return '即将开始：${item.category}';
  }

  int _notificationId(int scheduleId) {
    const maxSignedInt32 = 2147483647;
    if (scheduleId <= 0) {
      return DateTime.now().millisecondsSinceEpoch.remainder(maxSignedInt32);
    }
    return scheduleId.remainder(maxSignedInt32);
  }
}
