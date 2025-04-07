import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/skill_model.dart';
import '../../../models/user_model.dart';
import '../../../services/swap_service.dart';
import '../../../state/user_state.dart';

class UserProfileSheet extends StatefulWidget {
  final UserModel user;
  final VoidCallback onSwapRequested;

  const UserProfileSheet({
    Key? key,
    required this.user,
    required this.onSwapRequested,
  }) : super(key: key);

  @override
  State<UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<UserProfileSheet> {
  bool _hasRequestPending = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final currentUser = context.read<UserState>().currentUser;
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final swapService = context.read<SwapService>();
      final hasRequest = await swapService.hasExistingRequest(
        currentUser.id,
        widget.user.id,
      );

      if (mounted) {
        setState(() {
          _hasRequestPending = hasRequest;
        });
      }
    } catch (e) {
      print('Error checking request status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRequestPress() async {
    if (_isLoading) return;

    final currentUser = context.read<UserState>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send requests')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final swapService = context.read<SwapService>();

      if (_hasRequestPending) {
        await swapService.cancelSwapRequest(
          currentUser.id,
          widget.user.id,
        );
        if (mounted) {
          setState(() {
            _hasRequestPending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request cancelled')),
          );
        }
      } else {
        await swapService.createSwapRequest(
          senderId: currentUser.id,
          receiverId: widget.user.id,
        );
        if (mounted) {
          setState(() {
            _hasRequestPending = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request sent successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          AppBar(
            title: Text(widget.user.name),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSkillsSection('Skills Offering', widget.user.skillsOffering),
                const SizedBox(height: 16),
                _buildSkillsSection('Skills Seeking', widget.user.skillsSeeking),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRequestPress,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: _hasRequestPending 
                    ? Colors.red // Red for cancel button
                    : Theme.of(context).primaryColor,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _hasRequestPending ? 'Cancel Request' : 'Request Skill Swap',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: widget.user.profileImageUrl != null
              ? NetworkImage(widget.user.profileImageUrl!)
              : const AssetImage('assets/placeholder_profile.png') as ImageProvider,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: const TextStyle(fontSize: 24)),
              Text('Member since ${_formatDate(widget.user.joinDate)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(String title, List<Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Chip(
            label: Text(skill.name),
            avatar: CircleAvatar(
              child: Text(skill.proficiency.toString()),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}