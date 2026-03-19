import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lunar/calendar/Lunar.dart';
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
    final today = stripTime(DateTime.now());
    final todaySchedules = ref.watch(daySchedulesProvider(today));
    final monthMap = ref.watch(
      monthEventMapProvider(DateTime(focusedDay.year, focusedDay.month)),
    );

    final bgBytes = ref.watch(backgroundImageBytesProvider);
    final bgImage = bgBytes == null ? null : MemoryImage(bgBytes);
    final themeMode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.light;
    final isDarkMode = themeMode == ThemeMode.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('本地日历'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.nightlight_round),
            tooltip: isDarkMode ? '切换为浅色模式' : '切换为深色模式',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.wallpaper_outlined),
            tooltip: '背景设置',
            onPressed: () => _openBackgroundActions(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增日程',
            onPressed: () => _openForm(context, ref, initialDate: selectedDay),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: isDarkMode
                ? ColoredBox(color: surfaceColor)
                : bgImage == null
                    ? const ColoredBox(color: Colors.white)
                    : Image(
                        image: bgImage,
                        fit: BoxFit.cover,
                      ),
          ),
          Positioned.fill(
            child: Container(
              color: isDarkMode
                  ? Colors.transparent
                  : bgImage == null
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('月视图'),
                      selected: calendarFormat == CalendarFormat.month,
                      selectedColor: isDarkMode ? surfaceColor : null,
                      backgroundColor: isDarkMode ? surfaceColor : null,
                      side: isDarkMode
                          ? BorderSide(
                              color: calendarFormat == CalendarFormat.month
                                  ? onSurfaceColor
                                  : onSurfaceColor.withValues(alpha: 0.35),
                            )
                          : null,
                      labelStyle: isDarkMode
                          ? TextStyle(color: onSurfaceColor)
                          : null,
                      onSelected: (_) {
                        ref.read(calendarFormatProvider.notifier).state =
                            CalendarFormat.month;
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('周视图'),
                      selected: calendarFormat == CalendarFormat.week,
                      selectedColor: isDarkMode ? surfaceColor : null,
                      backgroundColor: isDarkMode ? surfaceColor : null,
                      side: isDarkMode
                          ? BorderSide(
                              color: calendarFormat == CalendarFormat.week
                                  ? onSurfaceColor
                                  : onSurfaceColor.withValues(alpha: 0.35),
                            )
                          : null,
                      labelStyle: isDarkMode
                          ? TextStyle(color: onSurfaceColor)
                          : null,
                      onSelected: (_) {
                        ref.read(calendarFormatProvider.notifier).state =
                            CalendarFormat.week;
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDarkMode
                      ? surfaceColor
                      : Theme.of(context).colorScheme.surface.withValues(alpha: 0.74),
                ),
                child: TableCalendar<ScheduleItem>(
                  locale: 'zh_CN',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  firstDay: DateTime(2020, 1, 1),
                  lastDay: DateTime(2100, 12, 31),
                  focusedDay: focusedDay,
                  calendarFormat: calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  eventLoader: (day) => monthMap[stripTime(day)] ?? const [],
                  availableGestures: AvailableGestures.horizontalSwipe,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 0,
                    outsideDaysVisible: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      hasEvent: (monthMap[stripTime(day)]?.isNotEmpty ?? false),
                    ),
                    outsideBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isOutside: true,
                      hasEvent: (monthMap[stripTime(day)]?.isNotEmpty ?? false),
                    ),
                    todayBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isToday: true,
                      hasEvent: (monthMap[stripTime(day)]?.isNotEmpty ?? false),
                    ),
                    selectedBuilder: (context, day, _) => _buildDayCell(
                      context,
                      day,
                      isSelected: true,
                      hasEvent: (monthMap[stripTime(day)]?.isNotEmpty ?? false),
                    ),
                  ),
                  onDaySelected: (selected, focused) {
                    ref.read(selectedDayProvider.notifier).state = stripTime(selected);
                    ref.read(focusedDayProvider.notifier).state = focused;
                  },
                  onPageChanged: (focused) {
                    ref.read(focusedDayProvider.notifier).state = focused;
                  },
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
                          backgroundImage: isDarkMode ? null : bgImage,
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
              const Divider(height: 1),
              SizedBox(
                height: 180,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日日程',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: todaySchedules.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const Center(child: Text('今天暂无日程'));
                            }
                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final timeText = item.isAllDay
                                    ? '全天'
                                    : '${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}';
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _openForm(
                                    context,
                                    ref,
                                    schedule: item,
                                    initialDate: today,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: isDarkMode
                                          ? surfaceColor
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                      border: isDarkMode
                                          ? Border.all(
                                              color: onSurfaceColor.withValues(alpha: 0.12),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$timeText  ·  ${item.category}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _deleteSchedule(context, ref, item.id),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('今日日程加载失败：$error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    bool isOutside = false,
    bool isToday = false,
    bool isSelected = false,
    bool hasEvent = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final lunar = Lunar.fromDate(day);
    final holidayName = _holidayLabelForDay(day, lunar);
    final lunarText = holidayName ?? '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
    final isHoliday = _isHolidayDay(day, lunar);

    Color? bgColor;
    Color textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    Color lunarColor = theme.textTheme.bodySmall?.color ?? Colors.black54;
    Border? border;

    if (isDarkMode) {
      bgColor = colorScheme.surface;
      textColor = isOutside
          ? colorScheme.onSurface.withValues(alpha: 0.5)
          : colorScheme.onSurface;
      lunarColor = isOutside
          ? colorScheme.onSurface.withValues(alpha: 0.4)
          : colorScheme.onSurface.withValues(alpha: 0.75);

      if (isSelected) {
        border = Border.all(color: colorScheme.onSurface, width: 1.3);
      } else if (isToday) {
        border = Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.65),
          width: 1.0,
        );
      }
    } else {
      if (isSelected) {
        bgColor = colorScheme.primary;
        textColor = colorScheme.onPrimary;
        lunarColor = colorScheme.onPrimary.withValues(alpha: 0.9);
      } else if (isToday) {
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        lunarColor = colorScheme.onPrimaryContainer.withValues(alpha: 0.9);
      } else if (isOutside) {
        textColor = theme.disabledColor;
        lunarColor = theme.disabledColor.withValues(alpha: 0.85);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        border: border,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 20,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                ),
                if (isHoliday)
                  const Positioned(
                    top: -2,
                    right: -6,
                    child: _HolidayRestBadge(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            lunarText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: lunarColor),
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: hasEvent
                  ? (isDarkMode
                      ? colorScheme.onSurface
                      : (isSelected ? colorScheme.onPrimary : colorScheme.primary))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String? _holidayLabelForDay(DateTime day, Lunar lunar) {
    if (day.month == 1 && day.day == 1) {
      return '元旦';
    }
    if (day.month == 4 && day.day == 4) {
      return '清明节';
    }
    if (day.month == 5 && day.day == 1) {
      return '劳动节';
    }
    if (day.month == 6 && day.day == 20) {
      return '端午节';
    }
    if (day.month == 9 && day.day == 27) {
      return '中秋节';
    }
    if (day.month == 10 && day.day == 1) {
      return '国庆节';
    }

    final lunarMonth = lunar.getMonthInChinese();
    final lunarDay = lunar.getDayInChinese();

    if (lunarMonth == '正' && lunarDay == '初一') {
      return '春节';
    }
    if (lunarMonth == '五' && lunarDay == '初五') {
      return '端午节';
    }
    if (lunarMonth == '八' && lunarDay == '十五') {
      return '中秋节';
    }
    return null;
  }

  bool _isHolidayDay(DateTime day, Lunar lunar) {
    if (day.month == 1 && day.day == 1) {
      return true;
    }
    if (_isGregorianRange(day, 4, 4, 4, 6)) {
      return true;
    }
    if (_isGregorianRange(day, 5, 1, 5, 5)) {
      return true;
    }
    if (_isGregorianRange(day, 6, 20, 6, 22)) {
      return true;
    }
    if (_isGregorianRange(day, 9, 27, 9, 29)) {
      return true;
    }
    if (_isGregorianRange(day, 10, 1, 10, 7)) {
      return true;
    }

    final lunarMonth = lunar.getMonthInChinese();
    final lunarDay = lunar.getDayInChinese();
    if (lunarMonth == '正') {
      const springFestivalDays = <String>{
        '初一',
        '初二',
        '初三',
        '初四',
        '初五',
        '初六',
        '初七',
      };
      if (springFestivalDays.contains(lunarDay)) {
        return true;
      }
    }
    if (lunarMonth == '五' && lunarDay == '初五') {
      return true;
    }
    if (lunarMonth == '八' && lunarDay == '十五') {
      return true;
    }
    return false;
  }

  bool _isGregorianRange(
    DateTime day,
    int startMonth,
    int startDay,
    int endMonth,
    int endDay,
  ) {
    final normalized = DateTime(day.year, day.month, day.day);
    final start = DateTime(day.year, startMonth, startDay);
    final end = DateTime(day.year, endMonth, endDay);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  Future<void> _openBackgroundActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择背景图'),
              onTap: () => Navigator.of(context).pop('pick'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('清除背景图'),
              onTap: () => Navigator.of(context).pop('clear'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    if (action == 'pick') {
      await _pickBackgroundImage(context, ref);
      return;
    }
    if (action == 'clear') {
      await ref.read(backgroundImageProvider.notifier).saveBase64(null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除背景图')),
        );
      }
    }
  }

  Future<void> _pickBackgroundImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 75,
    );

    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片读取失败，请重试')),
        );
      }
      return;
    }

    final base64Image = base64Encode(bytes);
    await ref.read(backgroundImageProvider.notifier).saveBase64(base64Image);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('背景图已更新')),
      );
    }
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

class _HolidayRestBadge extends StatelessWidget {
  const _HolidayRestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF2FB54A),
        shape: BoxShape.circle,
      ),
      child: const Text(
        '休',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}
