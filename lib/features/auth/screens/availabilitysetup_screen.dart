import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AvailabilitySetupScreen extends StatefulWidget {
  const AvailabilitySetupScreen({super.key});

  @override
  State<AvailabilitySetupScreen> createState() => _AvailabilitySetupScreenState();
}

class _AvailabilitySetupScreenState extends State<AvailabilitySetupScreen> {
  final Map<int, Set<TimeOfDay>> _availability = {};
  bool _useDefaultAvailability = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Set Default Availability'),
          value: _useDefaultAvailability,
          onChanged: (value) => setState(() => _useDefaultAvailability = value),
        ),
        if (_useDefaultAvailability)
          _buildDefaultAvailability()
        else
          _buildWeeklyCalendar(),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    return Expanded(
      child: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          final weekday = index + 1;
          return ExpansionTile(
            title: Text(DateFormat('EEEE').format(
              DateTime.now().subtract(Duration(days: DateTime.now().weekday - weekday))
            )),
            children: [
              _buildTimeSlotSelector(weekday),
            ],
          );
        },
      ),
    );
  }


  Widget _buildDefaultAvailability() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Default Available Hours',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTimeRangePicker(
          label: 'Start Time',
          initialTime: const TimeOfDay(hour: 9, minute: 0),
          onChanged: (time) {
            // Handle start time change
          },
        ),
        const SizedBox(height: 16),
        _buildTimeRangePicker(
          label: 'End Time',
          initialTime: const TimeOfDay(hour: 17, minute: 0),
          onChanged: (time) {
            // Handle end time change
          },
        ),
      ],
    ),
  );
}

Widget _buildTimeSlotSelector(int weekday) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Column(
      children: [
        CheckboxListTile(
          title: const Text('Available'),
          value: _availability[weekday]?.isNotEmpty ?? false,
          onChanged: (checked) {
            setState(() {
              if (checked!) {
                _availability[weekday] = {
                  const TimeOfDay(hour: 9, minute: 0),
                  const TimeOfDay(hour: 17, minute: 0),
                };
              } else {
                _availability[weekday]?.clear();
              }
            });
          },
        ),
        if (_availability[weekday]?.isNotEmpty ?? false) ...[
          _buildTimeRangePicker(
            label: 'Start Time',
            initialTime: _availability[weekday]?.first ?? 
                const TimeOfDay(hour: 9, minute: 0),
            onChanged: (time) {
              setState(() {
                _availability[weekday] = {
                  time,
                  _availability[weekday]?.last ?? const TimeOfDay(hour: 17, minute: 0),
                };
              });
            },
          ),
          const SizedBox(height: 8),
          _buildTimeRangePicker(
            label: 'End Time',
            initialTime: _availability[weekday]?.last ?? 
                const TimeOfDay(hour: 17, minute: 0),
            onChanged: (time) {
              setState(() {
                _availability[weekday] = {
                  _availability[weekday]?.first ?? const TimeOfDay(hour: 9, minute: 0),
                  time,
                };
              });
            },
          ),
        ],
      ],
    ),
  );
}

Widget _buildTimeRangePicker({
  required String label,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onChanged,
}) {
  return Row(
    children: [
      Text(label),
      const SizedBox(width: 16),
      TextButton(
        onPressed: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );
          if (time != null) {
            onChanged(time);
          }
        },
        child: Text(initialTime.format(context)),
      ),
    ],
  );
}
}