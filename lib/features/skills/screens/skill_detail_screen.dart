import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/skill_state.dart';
import 'package:skillswap/features/profile/screens/profile_screen.dart';

class SkillDetailScreen extends StatelessWidget {
  final Skill skill;

  const SkillDetailScreen({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    final skillState = context.watch<SkillState>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(skill.name),
      ),
      body: Column(
        children: [
          _SkillOverview(skill: skill),
          const Divider(),
          Expanded(
            child: _PeopleOfferingList(
              users: skillState.getUsersOfferingSkill(skill.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillOverview extends StatelessWidget {
  final Skill skill;

  const _SkillOverview({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skill.category,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            skill.description ?? 'No description available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(Icons.people, '${skill.usersOffering.length} offering'),
              const SizedBox(width: 16),
              _buildStatItem(Icons.star, '${skill.averageRating.toStringAsFixed(1)}/5'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}

class _PeopleOfferingList extends StatelessWidget {
  final List<UserModel> users;

  const _PeopleOfferingList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No one is offering this skill yet'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final skill = user.skillsOffering.firstWhere(
          (s) => s.id == user.skillsOffering[index].id);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
          ),
          title: Text(user.name),
          subtitle: Text('Level ${skill.proficiency}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: user.id),
            ),
          ),
        );
      },
    );
  }
}