import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/user_model.dart';
import 'package:skillswap/state/user_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final UserModel _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserState>().currentUser!;
    _nameController = TextEditingController(text: _currentUser.name);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await context.read<UserState>().updateProfile(
            _currentUser.copyWith(name: _nameController.text.trim(), skillsOffering: [], skillsSeeking: []),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Profile Picture'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _changeProfilePicture(),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _currentUser.profileImageUrl != null
                    ? NetworkImage(_currentUser.profileImageUrl!)
                    : const AssetImage('assets/placeholder_profile.png')
                        as ImageProvider,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture() async {
    // Implement image picker logic
  }
}