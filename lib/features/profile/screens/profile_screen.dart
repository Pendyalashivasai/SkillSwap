import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/features/profile/screens/edit_profile_screen.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/user_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _userFuture;
  bool _isLoading = true;
  String? _errorMessage;
  late String _userId;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = context.read<UserState>();
      setState(() {
        _userId = widget.userId ?? userState.currentUserId ?? '';
        print("ProfileScreen: Using user ID: $_userId");
      });
      _validateAndLoadUser();
    });
  }

  void _validateAndLoadUser() {
    print("ProfileScreen: Validating user ID: $_userId");
    if (_userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid user ID';
      });
      return;
    }
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userState = context.read<UserState>();
      print("ProfileScreen: Loading user with ID: $_userId");
      
      // Force a fresh load
      final user = await userState.getUser(_userId);
      
      if (!mounted) return;
      
      if (user == null) {
        print("ProfileScreen: User not found: $_userId");
        setState(() {
          _errorMessage = 'User not found';
        });
      } else {
        print("ProfileScreen: User loaded with image: ${user.profileImageUrl}");
        setState(() {
          _userFuture = Future.value(user);
        });
      }
    } catch (error) {
      print("ProfileScreen: Error loading user: $error");
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final isCurrentUser = widget.userId == userState.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      actions: [
        if (isCurrentUser) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ],
    ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUser,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUser,
      child: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('No user data available'));
          }

          final user = snapshot.data!;
          return _buildProfileContent(user);
        },
      ),
    );
  }

Future<void> _handleLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    try {
      await context.read<AuthController>().logout();
      if (mounted) {
        context.go('/login'); // Navigate to login screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }
}


  Widget _buildProfileContent(UserModel user) {
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
  }

  void _navigateToEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );

    if (mounted && result == true) {
      setState(() {
        _userFuture = context.read<UserState>().getUser(_userId);
      });
      _loadUser();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    print('ProfileHeader: Building with profileImageUrl - ${user.profileImageUrl}');
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? const Icon(Icons.person, size: 40)
              : null,
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
