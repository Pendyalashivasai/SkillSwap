import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/user_state.dart';

import '../../../models/skill_model.dart';
import '../../auth/screens/skillselection_screen.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final UserModel _currentUser;
  bool _isLoading = false;
  Set<Skill> _skillsOffering = {};
  Set<Skill> _skillsSeeking = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserState>().currentUser!;
    _nameController = TextEditingController(text: _currentUser.name);
    _skillsOffering = Set.from(_currentUser.skillsOffering);
    _skillsSeeking = Set.from(_currentUser.skillsSeeking);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      print('EditProfileScreen: Current user profileImageUrl - ${_currentUser.profileImageUrl}');

      final updatedUser = _currentUser.copyWith(
        name: _nameController.text.trim(),
        skillsOffering: _skillsOffering.toList(),
        skillsSeeking: _skillsSeeking.toList(),
        profileImageUrl: _currentUser.profileImageUrl, // Explicitly preserve profileImageUrl
      );

      print('EditProfileScreen: Updated user profileImageUrl - ${updatedUser.profileImageUrl}');

      await context.read<UserState>().updateProfile(updatedUser);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

   Future<void> _changeProfilePicture() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Compress image
        maxHeight: 1024,
        imageQuality: 85, // Reduce quality to decrease file size
      );
      
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = context.read<UserState>().currentUserId!;
      await context.read<ProfileService>().updateProfilePicture(
        userId,
        pickedFile.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Edit Profile'),
      actions: [
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfilePicture(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),
          _buildSkillsSection(
            'Skills Offering',
            _skillsOffering,
            (skills) => setState(() => _skillsOffering = skills),
            true,
          ),
          const SizedBox(height: 24),
          _buildSkillsSection(
            'Skills Seeking',
            _skillsSeeking,
            (skills) => setState(() => _skillsSeeking = skills),
            false,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSkillsSection(
    String title,
    Set<Skill> skills,
    Function(Set<Skill>) onChanged,
    bool isTeachingSkills,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showSkillSelectionDialog(
                skills, 
                onChanged,
                isTeachingSkills,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Chip(
            label: Text(skill.name),
            avatar: CircleAvatar(
              child: Text(skill.proficiency.toString()),
            ),
            onDeleted: () {
              setState(() {
                skills.remove(skill);
                onChanged(skills);
              });
            },
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _showSkillSelectionDialog(
    Set<Skill> currentSkills,
    Function(Set<Skill>) onChanged,
    bool isTeachingSkills,
  ) async {
    final result = await showModalBottomSheet<Set<Skill>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => SkillSelectionScreen(
          initialSkills: currentSkills,
          isEditMode: true,
          isTeachingSkills: isTeachingSkills,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        onChanged(result);
      });
    }
  }

 Widget _buildProfilePicture() {
    final user = context.watch<UserState>().currentUser;
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user?.profileImageUrl != null
                ? NetworkImage(user!.profileImageUrl!)
                : null,
            child: user?.profileImageUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _isLoading ? null : _changeProfilePicture,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }


}