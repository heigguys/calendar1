import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/schedule_item.dart';

class IsarDatabase {
  IsarDatabase._();

  static Future<Isar> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [ScheduleItemSchema],
      name: 'calendar_local_v2',
      directory: dir.path,
    );
  }
}
