import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/features/sessions/services/session_service.dart' as service;
import 'package:skillswap/models/session_model.dart';
import 'package:skillswap/state/session_state.dart';
import 'package:skillswap/widgets/user_avatar.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>().getSession(widget.sessionId);
    if (session == null) {
      return const Scaffold(body: Center(child: Text('Session not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionHeader(session),
            const SizedBox(height: 20),
            _buildSessionInfo(session),
            const SizedBox(height: 20),
            if (session.notes.isNotEmpty) _buildNotesSection(session),
            const Spacer(),
            if (session.status == SessionStatus.pending)
              _buildActionButtons(context, session),
          ],
        ),
      ),
    );
  }

 Widget _buildSessionHeader(Session session) {
  return Row(
    children: [
      UserAvatar(userId: session.teacherId, radius: 30),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.skillName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatSessionTime(session.startTime, session.endTime),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

String _formatSessionTime(DateTime startTime, DateTime endTime) {
  final dateStr = startTime.toLocal().toString().split(' ')[0];
  final startHour = startTime.toLocal().hour.toString().padLeft(2, '0');
  final startMinute = startTime.toLocal().minute.toString().padLeft(2, '0');
  final endHour = endTime.toLocal().hour.toString().padLeft(2, '0');
  final endMinute = endTime.toLocal().minute.toString().padLeft(2, '0');
  
  return '$dateStr • $startHour:$startMinute - $endHour:$endMinute';
}

  Widget _buildSessionInfo(Session session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', _getStatusText(session.status)),
            _buildInfoRow('Mode', session.mode == SessionMode.online ? 'Online' : 'In-Person'),
            _buildInfoRow('Duration', '${session.duration.inMinutes} minutes'),
            if (session.mode == SessionMode.inPerson)
              _buildInfoRow('Location', session.location ?? 'To be determined'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNotesSection(Session session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(session.notes),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Session session) {
    final isTeacher = session.teacherId == context.read<SessionState>().currentUserId;

    return Row(
      children: [
        if (isTeacher) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, session, SessionStatus.rejected),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(context, session, SessionStatus.confirmed),
              child: const Text('Accept'),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _cancelSession(context, session),
              child: const Text('Cancel Request'),
            ),
          ),
        ],
      ],
    );
  }

 Future<void> _updateStatus(BuildContext context, Session session, SessionStatus status) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm ${status.name}'),
      content: Text('Are you sure you want to ${status.name.toLowerCase()} this session?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await context.read<SessionState>().updateSessionStatus(session.id, status);
    if (!mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session ${status.name.toLowerCase()}')),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

Future<void> _cancelSession(BuildContext context, Session session) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel Session'),
      content: const Text('Are you sure you want to cancel this session?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await context.read<SessionState>().cancelSession(session.id);
    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  String _getStatusText(SessionStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}