import 'package:flutter/material.dart';

class SkillCard extends StatelessWidget {
  final String skillName;
  final String userName;
  final int matchPercentage;

  const SkillCard({
    super.key,
    required this.skillName,
    required this.userName,
    required this.matchPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  skillName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('$matchPercentage% match'),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Offered by $userName'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View Profile'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Request Swap'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}