import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/session_model.dart';
import 'package:skillswap/state/session_state.dart';
import 'package:skillswap/widgets/duration_picker.dart';

class SessionRequestScreen extends StatefulWidget {
  final String skillId;
  final String teacherId;

  const SessionRequestScreen({
    super.key,
    required this.skillId,
    required this.teacherId,
  });

  @override
  State<SessionRequestScreen> createState() => _SessionRequestScreenState();
}

class _SessionRequestScreenState extends State<SessionRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Duration _duration = const Duration(minutes: 30);
  SessionMode _mode = SessionMode.online;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Session')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDatePicker(),
              const SizedBox(height: 20),
              _buildTimePicker(),
              const SizedBox(height: 20),
              DurationPicker(
                duration: _duration,
                onChanged: (duration) => setState(() => _duration = duration),
              ),
              const SizedBox(height: 20),
              _buildModeSelector(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitRequest,
                child: const Text('Send Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text(
        _selectedDate == null
            ? 'Select Date'
            : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      title: Text(
        _selectedTime == null
            ? 'Select Time'
            : 'Time: ${_selectedTime!.format(context)}',
      ),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Session Mode'),
        Row(
          children: [
            Radio<SessionMode>(
              value: SessionMode.online,
              groupValue: _mode,
              onChanged: (value) => setState(() => _mode = value!),
            ),
            const Text('Online'),
            Radio<SessionMode>(
              value: SessionMode.inPerson,
              groupValue: _mode,
              onChanged: (value) => setState(() => _mode = value!),
            ),
            const Text('In-Person'),
          ],
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      skillId: widget.skillId,
      teacherId: widget.teacherId,
      studentId: context.read<SessionState>().currentUserId,
      startTime: startTime,
      endTime: startTime.add(_duration),
      mode: _mode,
      status: SessionStatus.pending,
      notes: _notesController.text,
      createdAt: DateTime.now(), skillName: '',
    );

    try {
      await context.read<SessionState>().requestSession(session);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session requested successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}