import 'dart:async';

import 'package:isar/isar.dart';

import '../models/schedule_item.dart';
import 'notification_service.dart';
import 'schedule_service.dart';

class WebScheduleService implements ScheduleServiceBase {
  WebScheduleService(this._notificationService);

  final NotificationService _notificationService;
  final StreamController<void> _changedController = StreamController<void>.broadcast();
  final List<ScheduleItem> _items = <ScheduleItem>[];
  int _nextId = 1;

  @override
  Future<Id> addSchedule(ScheduleItem item) async {
    final now = DateTime.now();
    item.id = _nextId++;
    item.createdAt = now;
    item.updatedAt = now;
    _items.add(item);
    _sort();
    await _notificationService.scheduleOrUpdateReminder(item);
    _notifyChanged();
    return item.id;
  }

  @override
  Future<void> deleteSchedule(Id id) async {
    _items.removeWhere((item) => item.id == id);
    await _notificationService.cancelReminder(id);
    _notifyChanged();
  }

  @override
  Future<List<ScheduleItem>> getSchedulesForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _items
        .where((item) => item.startTime.isBefore(end) && item.endTime.isAfter(start))
        .toList(growable: false);
  }

  @override
  Future<List<ScheduleItem>> getSchedulesInRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    return _items
        .where(
          (item) => item.startTime.isBefore(rangeEnd) && item.endTime.isAfter(rangeStart),
        )
        .toList(growable: false);
  }

  @override
  Future<void> updateSchedule(ScheduleItem item) async {
    item.updatedAt = DateTime.now();
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    _sort();
    await _notificationService.scheduleOrUpdateReminder(item);
    _notifyChanged();
  }

  @override
  Future<void> upsertSchedule(ScheduleItem item) async {
    if (item.id == Isar.autoIncrement || item.id <= 0) {
      await addSchedule(item);
      return;
    }
    await updateSchedule(item);
  }

  @override
  Stream<List<ScheduleItem>> watchSchedulesForDay(DateTime day) async* {
    yield await getSchedulesForDay(day);
    yield* _changedController.stream.asyncMap((_) => getSchedulesForDay(day));
  }

  @override
  Stream<List<ScheduleItem>> watchSchedulesInRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async* {
    yield await getSchedulesInRange(rangeStart, rangeEnd);
    yield* _changedController.stream.asyncMap(
      (_) => getSchedulesInRange(rangeStart, rangeEnd),
    );
  }

  void _notifyChanged() {
    if (!_changedController.isClosed) {
      _changedController.add(null);
    }
  }

  void _sort() {
    _items.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  void dispose() {
    _changedController.close();
  }
}
