import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../database/isar_database.dart';
import '../models/schedule_item.dart';
import '../services/notification_service.dart';
import '../services/schedule_service.dart';
import '../services/web_schedule_service.dart';

DateTime stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('NotificationService must be overridden in main.dart'),
);

class BackgroundImageController extends AsyncNotifier<String?> {
  static const String _key = 'calendar_bg_image_base64';

  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveBase64(String? base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    if (base64Image == null || base64Image.isEmpty) {
      await prefs.remove(_key);
      state = const AsyncData(null);
      return;
    }
    await prefs.setString(_key, base64Image);
    state = AsyncData(base64Image);
  }
}

final backgroundImageProvider =
    AsyncNotifierProvider<BackgroundImageController, String?>(
  BackgroundImageController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const String _key = 'calendar_theme_mode';
  static const String _light = 'light';
  static const String _dark = 'dark';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return value == _dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? ThemeMode.light;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _save(next);
    state = AsyncData(next);
  }

  Future<void> _save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = mode == ThemeMode.dark ? _dark : _light;
    await prefs.setString(_key, raw);
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final backgroundImageBytesProvider = Provider<Uint8List?>((ref) {
  final raw = ref.watch(backgroundImageProvider).valueOrNull;
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    return base64Decode(raw);
  } catch (_) {
    return null;
  }
});

final isarProvider = FutureProvider<Isar>((ref) async {
  final isar = await IsarDatabase.open();
  ref.onDispose(() {
    if (isar.isOpen) {
      isar.close();
    }
  });
  return isar;
});

final scheduleServiceProvider = FutureProvider<ScheduleServiceBase>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);

  if (kIsWeb) {
    final service = WebScheduleService(notificationService);
    ref.onDispose(service.dispose);
    return service;
  }

  final isar = await ref.watch(isarProvider.future);
  final service = ScheduleService(isar, notificationService);
  ref.onDispose(service.dispose);
  return service;
});

final selectedDayProvider = StateProvider<DateTime>(
  (ref) => stripTime(DateTime.now()),
);

final focusedDayProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final calendarFormatProvider = StateProvider<CalendarFormat>(
  (ref) => CalendarFormat.month,
);

final daySchedulesProvider =
    StreamProvider.family.autoDispose<List<ScheduleItem>, DateTime>(
  (ref, day) async* {
    final service = await ref.watch(scheduleServiceProvider.future);
    yield* service.watchSchedulesForDay(stripTime(day));
  },
);

final monthSchedulesProvider =
    StreamProvider.family.autoDispose<List<ScheduleItem>, DateTime>(
  (ref, month) async* {
    final service = await ref.watch(scheduleServiceProvider.future);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    yield* service.watchSchedulesInRange(start, end);
  },
);

final monthEventMapProvider =
    Provider.family.autoDispose<Map<DateTime, List<ScheduleItem>>, DateTime>(
  (ref, month) {
    final monthSchedules = ref.watch(monthSchedulesProvider(month)).valueOrNull ?? [];
    final map = <DateTime, List<ScheduleItem>>{};
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    for (final schedule in monthSchedules) {
      var cursor = stripTime(schedule.startTime);
      var end = stripTime(schedule.endTime);

      if (cursor.isBefore(monthStart)) {
        cursor = monthStart;
      }
      if (end.isAfter(monthEnd)) {
        end = monthEnd;
      }

      while (!cursor.isAfter(end)) {
        map.putIfAbsent(cursor, () => []);
        map[cursor]!.add(schedule);
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return map;
  },
);
