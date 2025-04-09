import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/user_model.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/skill_model.dart';
import '../../../state/skill_state.dart';
import '../../../state/user_state.dart';

class SkillSelectionScreen extends StatefulWidget {
  final Set<Skill> initialSkills;
  final bool isEditMode;
  final bool isTeachingSkills; // Add this parameter

  const SkillSelectionScreen({
    super.key,
    this.initialSkills = const {},  // Default empty set
    this.isEditMode = false,
    this.isTeachingSkills = true, // Default to teaching skills
  });
  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  final _searchController = TextEditingController();
  late Set<Skill> _teachingSkills = {};
  late Set<Skill> _learningSkills = {};

  @override
  void initState() {
    super.initState();
    // Initialize with passed in skills
    _teachingSkills = Set.from(widget.initialSkills);
    _learningSkills = Set.from(widget.initialSkills);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Wrap with Scaffold
      appBar: AppBar(
        title: const Text('Select Skills'),
        actions: [
          TextButton(
            onPressed: _saveSkills,
            child: const Text('Save'),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Skills to Teach'),
                Tab(text: 'Skills to Learn'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSkillList(true),  // Teaching skills
                  _buildSkillList(false), // Learning skills
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _showAddCustomSkillDialog(),
                child: const Text('Add Custom Skill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillList(bool isTeaching) {
    return Consumer<SkillState>(
      builder: (context, skillState, child) {
        final skills = skillState.availableSkills;
        print('SkillSelectionScreen: Building skill list with ${skills.length} skills');
        
        if (skills.isEmpty) {
          print('SkillSelectionScreen: No skills available');
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final searchQuery = _searchController.text.toLowerCase();
        final filteredSkills = skills.where((skill) => 
          skill.name.toLowerCase().contains(searchQuery) ||
          skill.category.toLowerCase().contains(searchQuery)
        ).toList();

        print('SkillSelectionScreen: Filtered to ${filteredSkills.length} skills');

        return ListView.builder(
          itemCount: filteredSkills.length,
          itemBuilder: (context, index) {
            final skill = filteredSkills[index];
            final selectedSkills = isTeaching ? _teachingSkills : _learningSkills;
            final isSelected = selectedSkills.any((s) => s.id == skill.id);

            return ListTile(
              title: Text(skill.name),
              subtitle: Text(skill.category),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) _buildProficiencyDropdown(skill, selectedSkills),
                  Checkbox(
                    value: isSelected,
                    onChanged: (checked) => _toggleSkill(checked, skill, selectedSkills),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProficiencyDropdown(Skill skill, Set<Skill> selectedSkills) {
    return DropdownButton<int>(
      value: selectedSkills
          .firstWhere((s) => s.id == skill.id)
          .proficiency,
      items: [1, 2, 3, 4, 5].map((level) => 
        DropdownMenuItem(
          value: level,
          child: Text('Level $level'),
        ),
      ).toList(),
      onChanged: (level) {
        setState(() {
          selectedSkills.removeWhere((s) => s.id == skill.id);
          selectedSkills.add(skill.copyWith(proficiency: level!));
        });
      },
    );
  }

  void _toggleSkill(bool? checked, Skill skill, Set<Skill> selectedSkills) {
    setState(() {
      if (checked!) {
        selectedSkills.add(skill.copyWith(proficiency: 1));
      } else {
        selectedSkills.removeWhere((s) => s.id == skill.id);
      }
    });
  }

  Future<void> _showAddCustomSkillDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int selectedProficiency = 1;
    String selectedCategory = AppConstants.skillCategories.first;
    bool isTeaching = true; // Default to teaching skill

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Skill'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Skill Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a skill name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.skillCategories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedProficiency,
                  decoration: const InputDecoration(labelText: 'Proficiency Level'),
                  items: [1, 2, 3, 4, 5]
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text('Level $level'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedProficiency = value!),
                ),
                const SizedBox(height: 16),
               
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newSkill = Skill(
                    id: DateTime.now().toString(), // Temporary ID
                    name: nameController.text.trim(),
                    category: selectedCategory,
                    proficiency: selectedProficiency,
                  );

                  // Add to SkillState first
                  await context.read<SkillState>().addCustomSkill(newSkill);

                  if (mounted) {
                    Navigator.pop(context, {
                      'skill': newSkill,
                      'isTeaching': isTeaching,
                    });
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['isTeaching']) {
          _teachingSkills.add(result['skill']);
        } else {
          _learningSkills.add(result['skill']);
        }
      });
    }
  }

  Future<void> _saveSkills() async {
    try {
      final userState = context.read<UserState>();
      final currentUser = userState.currentUser;

      if (currentUser == null) {
        throw Exception('No user found');
      }

      // Create the updates map with only the skills being changed
      final Map<String, dynamic> updates = {};
      
      if (widget.isTeachingSkills) {
        updates['skillsOffering'] = _teachingSkills
            .map((s) => s.toMap())
            .toList();
      } else {
        updates['skillsSeeking'] = _learningSkills
            .map((s) => s.toMap())
            .toList();
      }

      // Update only the changed skills
      await userState.updateUserSkills(currentUser.id, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skills saved successfully')),
        );
        Navigator.pop(
          context, 
          widget.isTeachingSkills ? _teachingSkills : _learningSkills,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving skills: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}