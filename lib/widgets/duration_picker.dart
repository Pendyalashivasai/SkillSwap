import 'package:flutter/material.dart';

class DurationPicker extends StatelessWidget {
  final Duration duration;
  final ValueChanged<Duration> onChanged;

  const DurationPicker({
    super.key,
    required this.duration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration'),
        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: duration.inMinutes,
                items: [15, 30, 45, 60, 90, 120]
                    .map((minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes minutes'),
                        ))
                    .toList(),
                onChanged: (minutes) =>
                    onChanged(Duration(minutes: minutes!)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}