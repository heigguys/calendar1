import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/schedule_item.dart';
import '../providers/app_providers.dart';

class ScheduleFormPage extends ConsumerStatefulWidget {
  const ScheduleFormPage({
    super.key,
    this.schedule,
    required this.initialDate,
  });

  final ScheduleItem? schedule;
  final DateTime initialDate;

  @override
  ConsumerState<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends ConsumerState<ScheduleFormPage> {
  static const List<String> _presetCategories = ['工作', '生活', '学习'];
  static const String _customCategoryToken = '自定义';

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();

  late DateTime _startTime;
  late DateTime _endTime;
  bool _isAllDay = false;
  DateTime? _reminderTime;
  bool _saving = false;
  String _categoryMode = _presetCategories.first;

  bool get _isEditing => widget.schedule != null;
  bool get _isCustomCategory => _categoryMode == _customCategoryToken;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    if (schedule != null) {
      _titleController.text = schedule.title;
      _noteController.text = schedule.note;
      _startTime = schedule.startTime;
      _endTime = schedule.endTime;
      _isAllDay = schedule.isAllDay;
      _reminderTime = schedule.reminderTime;

      if (_presetCategories.contains(schedule.category)) {
        _categoryMode = schedule.category;
      } else {
        _categoryMode = _customCategoryToken;
        _customCategoryController.text = schedule.category;
      }
      return;
    }

    _startTime = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      DateTime.now().hour,
      0,
    );
    _endTime = _startTime.add(const Duration(hours: 1));
    _categoryMode = _presetCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy年MM月dd日');
    final dateTimeLabel = DateFormat('yyyy年MM月dd日 HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日程' : '新增日程'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryMode,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '工作', child: Text('工作')),
                DropdownMenuItem(value: '生活', child: Text('生活')),
                DropdownMenuItem(value: '学习', child: Text('学习')),
                DropdownMenuItem(value: '自定义', child: Text('自定义')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _categoryMode = value;
                });
              },
            ),
            if (_isCustomCategory) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: '自定义分类名称',
                  hintText: '例如：运动 / 旅行 / 家庭',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isCustomCategory && (value == null || value.trim().isEmpty)) {
                    return '请输入自定义分类名称';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isAllDay,
              title: const Text('全天'),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                  if (value) {
                    _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day);
                    _endTime = DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59);
                  }
                });
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('开始时间'),
              subtitle: Text(
                _isAllDay ? dateLabel.format(_startTime) : dateTimeLabel.format(_startTime),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () => _pickStartTime(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('结束时间'),
              subtitle: Text(
                _isAllDay ? dateLabel.format(_endTime) : dateTimeLabel.format(_endTime),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () => _pickEndTime(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('提醒时间'),
              subtitle: Text(
                _reminderTime == null ? '不提醒' : dateTimeLabel.format(_reminderTime!),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (_reminderTime != null)
                    IconButton(
                      onPressed: () => setState(() => _reminderTime = null),
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    onPressed: () => _pickReminderTime(context),
                    icon: const Icon(Icons.notifications_active_outlined),
                  ),
                ],
              ),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await _pickDateTime(context, initial: _startTime, allDay: _isAllDay);
    if (picked == null) {
      return;
    }
    setState(() {
      _startTime = picked;
      if (!_endTime.isAfter(_startTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await _pickDateTime(context, initial: _endTime, allDay: _isAllDay);
    if (picked == null) {
      return;
    }
    setState(() {
      _endTime = picked;
    });
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final base = _reminderTime ?? _startTime;
    final picked = await _pickDateTime(context, initial: base, allDay: false);
    if (picked == null) {
      return;
    }
    setState(() {
      _reminderTime = picked;
    });
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context, {
    required DateTime initial,
    required bool allDay,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      locale: const Locale('zh', 'CN'),
    );
    if (date == null) {
      return null;
    }
    if (allDay) {
      return DateTime(date.year, date.month, date.day);
    }

    if (!context.mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isAllDay && !_endTime.isAfter(_startTime)) {
      _showSnackBar('结束时间必须晚于开始时间');
      return;
    }
    if (_isAllDay && _endTime.isBefore(_startTime)) {
      _showSnackBar('结束日期不能早于开始日期');
      return;
    }

    final reminder = _reminderTime;
    if (reminder != null && !reminder.isBefore(_endTime)) {
      _showSnackBar('提醒时间建议早于结束时间');
      return;
    }

    final resolvedCategory = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _categoryMode;
    if (resolvedCategory.isEmpty) {
      _showSnackBar('请先设置分类');
      return;
    }

    setState(() => _saving = true);

    try {
      final service = await ref.read(scheduleServiceProvider.future);
      final item = widget.schedule ?? ScheduleItem();
      item.title = _titleController.text.trim();
      item.note = _noteController.text.trim();
      item.category = resolvedCategory;
      item.isAllDay = _isAllDay;
      item.startTime =
          _isAllDay ? DateTime(_startTime.year, _startTime.month, _startTime.day) : _startTime;
      item.endTime = _isAllDay
          ? DateTime(_endTime.year, _endTime.month, _endTime.day, 23, 59)
          : _endTime;
      item.reminderTime = _reminderTime;

      await service.upsertSchedule(item);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('保存失败：$e');
      setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
