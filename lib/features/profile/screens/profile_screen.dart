import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/features/profile/screens/edit_profile_screen.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/user_state.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    _userFuture = context.read<UserState>().getUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final isCurrentUser = widget.userId == userState.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditProfile(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadUser();
          });
        },
        child: FutureBuilder<UserModel?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to load profile'),
                    TextButton(
                      onPressed: () => _loadUser(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('User not found'));
            }

            final user = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 24),
                  _SkillsSection(
                    title: 'Skills Offering',
                    skills: user.skillsOffering,
                  ),
                  const SizedBox(height: 24),
                  _SkillsSection(
                    title: 'Skills Seeking',
                    skills: user.skillsSeeking,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadUser();
        });
      }
    });
  }
}
// Add after the _ProfileScreenState class:

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : const AssetImage('assets/placeholder_profile.png') as ImageProvider,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Member since ${_formatDate(user.joinDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SkillsSection extends StatelessWidget {
  final String title;
  final List<Skill> skills;

  const _SkillsSection({
    required this.title,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (skills.isEmpty)
          Text(
            'No skills added yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => _SkillChip(skill: skill)).toList(),
          ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final Skill skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(skill.name),
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          skill.proficiency.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}