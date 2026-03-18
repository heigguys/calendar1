import 'package:isar/isar.dart';

import '../models/schedule_item.dart';
import 'notification_service.dart';

class ScheduleService {
  ScheduleService(this._isar, this._notificationService);

  final Isar _isar;
  final NotificationService _notificationService;

  IsarCollection<ScheduleItem> get _collection => _isar.scheduleItems;

  Future<List<ScheduleItem>> getSchedulesForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _collection
        .filter()
        .startTimeLessThan(end)
        .and()
        .endTimeGreaterThan(start)
        .sortByStartTime()
        .findAll();
  }

  Future<List<ScheduleItem>> getSchedulesInRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    return _collection
        .filter()
        .startTimeLessThan(rangeEnd)
        .and()
        .endTimeGreaterThan(rangeStart)
        .sortByStartTime()
        .findAll();
  }

  Stream<List<ScheduleItem>> watchSchedulesForDay(DateTime day) async* {
    yield await getSchedulesForDay(day);
    yield* _collection.watchLazy().asyncMap((_) => getSchedulesForDay(day));
  }

  Stream<List<ScheduleItem>> watchSchedulesInRange(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async* {
    yield await getSchedulesInRange(rangeStart, rangeEnd);
    yield* _collection
        .watchLazy()
        .asyncMap((_) => getSchedulesInRange(rangeStart, rangeEnd));
  }

  Future<Id> addSchedule(ScheduleItem item) async {
    final now = DateTime.now();
    item.createdAt = now;
    item.updatedAt = now;

    late final Id id;
    await _isar.writeTxn(() async {
      id = await _collection.put(item);
    });

    item.id = id;
    await _notificationService.scheduleOrUpdateReminder(item);
    return id;
  }

  Future<void> updateSchedule(ScheduleItem item) async {
    item.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _collection.put(item);
    });

    await _notificationService.scheduleOrUpdateReminder(item);
  }

  Future<void> upsertSchedule(ScheduleItem item) async {
    if (item.id == Isar.autoIncrement) {
      await addSchedule(item);
      return;
    }
    await updateSchedule(item);
  }

  Future<void> deleteSchedule(Id id) async {
    await _isar.writeTxn(() async {
      await _collection.delete(id);
    });
    await _notificationService.cancelReminder(id);
  }
}
