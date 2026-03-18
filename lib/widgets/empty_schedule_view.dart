import 'package:flutter/material.dart';

class EmptyScheduleView extends StatelessWidget {
  const EmptyScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '当天暂无日程',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
