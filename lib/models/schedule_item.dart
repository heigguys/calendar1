import 'package:isar/isar.dart';

part 'schedule_item.g.dart';

@collection
class ScheduleItem {
  Id id = Isar.autoIncrement;

  @Index(caseSensitive: false)
  late String title;

  String note = '';

  @Index()
  late DateTime startTime;

  @Index()
  late DateTime endTime;

  bool isAllDay = false;

  DateTime? reminderTime;

  String category = '默认';

  late DateTime createdAt;

  late DateTime updatedAt;
}
