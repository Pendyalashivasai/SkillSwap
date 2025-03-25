import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/state/user_state.dart';

class SkillsEditScreen extends StatefulWidget {
  final bool isOffering;

  const SkillsEditScreen({
    super.key,
    required this.isOffering,
  });

  @override
  State<SkillsEditScreen> createState() => _SkillsEditScreenState();
}

class _SkillsEditScreenState extends State<SkillsEditScreen> {
  late List<Skill> _selectedSkills;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSkills = [
      ...(widget.isOffering
          ? context.read<UserState>().currentUser!.skillsOffering
          : context.read<UserState>().currentUser!.skillsSeeking)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.isOffering ? 'Offering' : 'Seeking'} Skills'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search skills',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildSkillsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSkills,
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildSkillsList() {
    final allSkills = context.read<UserState>().availableSkills;
    final query = _searchController.text.toLowerCase();

    return ListView.builder(
      itemCount: allSkills.length,
      itemBuilder: (context, index) {
        final skill = allSkills[index];
        if (query.isNotEmpty &&
            !skill.name.toLowerCase().contains(query)) {
          return const SizedBox.shrink();
        }

        final isSelected = _selectedSkills.any((s) => s.id == skill.id);
        return CheckboxListTile(
          title: Text(skill.name),
          subtitle: Text(skill.category),
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              selected!
                  ? _selectedSkills.add(skill)
                  : _selectedSkills.removeWhere((s) => s.id == skill.id);
            });
          },
          secondary: DropdownButton<int>(
            value: isSelected ? _selectedSkills.firstWhere((s) => s.id == skill.id).proficiency : 1,
            items: [1, 2, 3, 4, 5]
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text('Level $level'),
                    ))
                .toList(),
            onChanged: isSelected
                ? (level) {
                    setState(() {
                      final index = _selectedSkills.indexWhere((s) => s.id == skill.id);
                      _selectedSkills[index] = skill.copyWith(proficiency: level!);
                    });
                  }
                : null,
          ),
        );
      },
    );
  }

  Future<void> _saveSkills() async {
    if (widget.isOffering) {
      await context.read<UserState>().updateOfferingSkills(_selectedSkills);
    } else {
      await context.read<UserState>().updateSeekingSkills(_selectedSkills);
    }
    if (mounted) Navigator.pop(context);
  }
}