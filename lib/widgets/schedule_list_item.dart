import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_item.dart';

class ScheduleListItem extends StatelessWidget {
  const ScheduleListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final ScheduleItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeText = item.isAllDay
        ? '全天'
        : '${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(timeText),
            if (item.note.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.note.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(item.category),
                ),
                if (item.reminderTime != null)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(Icons.notifications_active_outlined, size: 16),
                    label: Text('已设置提醒'),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
