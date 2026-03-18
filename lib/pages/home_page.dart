import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/schedule_item.dart';
import '../providers/app_providers.dart';
import '../widgets/empty_schedule_view.dart';
import '../widgets/schedule_list_item.dart';
import 'schedule_form_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final daySchedules = ref.watch(daySchedulesProvider(selectedDay));
    final monthMap = ref.watch(
      monthEventMapProvider(DateTime(focusedDay.year, focusedDay.month)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地日历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增日程',
            onPressed: () => _openForm(context, ref, initialDate: selectedDay),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('月视图'),
                  selected: calendarFormat == CalendarFormat.month,
                  onSelected: (_) {
                    ref.read(calendarFormatProvider.notifier).state =
                        CalendarFormat.month;
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('周视图'),
                  selected: calendarFormat == CalendarFormat.week,
                  onSelected: (_) {
                    ref.read(calendarFormatProvider.notifier).state =
                        CalendarFormat.week;
                  },
                ),
              ],
            ),
          ),
          TableCalendar<ScheduleItem>(
            locale: 'zh_CN',
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: calendarFormat,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            eventLoader: (day) => monthMap[stripTime(day)] ?? const [],
            availableGestures: AvailableGestures.horizontalSwipe,
            onDaySelected: (selected, focused) {
              ref.read(selectedDayProvider.notifier).state = stripTime(selected);
              ref.read(focusedDayProvider.notifier).state = focused;
            },
            onPageChanged: (focused) {
              ref.read(focusedDayProvider.notifier).state = focused;
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN').format(selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: daySchedules.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyScheduleView();
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ScheduleListItem(
                      item: item,
                      onTap: () => _openForm(
                        context,
                        ref,
                        schedule: item,
                        initialDate: selectedDay,
                      ),
                      onDelete: () => _deleteSchedule(context, ref, item.id),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('加载失败：$error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ScheduleItem? schedule,
    required DateTime initialDate,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormPage(
          schedule: schedule,
          initialDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(BuildContext context, WidgetRef ref, int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日程'),
        content: const Text('确定要删除这个日程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final service = await ref.read(scheduleServiceProvider.future);
    await service.deleteSchedule(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日程已删除')),
      );
    }
  }
}
