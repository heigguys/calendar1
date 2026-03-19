import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_item.dart';

class ScheduleListItem extends StatelessWidget {
  const ScheduleListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
    this.backgroundImage,
  });

  final ScheduleItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final timeText = item.isAllDay
        ? '全天'
        : '${DateFormat('HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Ink(
            decoration: BoxDecoration(
              image: backgroundImage == null
                  ? null
                  : DecorationImage(
                      image: backgroundImage!,
                      fit: BoxFit.cover,
                      opacity: 0.22,
                    ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.90),
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
                ],
              ),
            ),
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
                  const SizedBox(height: 6),
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
          ),
        ),
      ),
    );
  }
}
