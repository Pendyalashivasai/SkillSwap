import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/core/constants/app_constants.dart';
import 'package:skillswap/models/skill_model.dart';
import 'package:skillswap/state/skill_state.dart';
import 'package:skillswap/features/skills/screens/skill_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final skillState = context.watch<SkillState>();
    
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('All'),
                      ...AppConstants.skillCategories
                          .map((category) => _buildCategoryChip(category))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildSkillList(skillState),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(category),
        selected: _selectedCategory == category,
        onSelected: (selected) => setState(() {
          _selectedCategory = selected ? category : 'All';
        }),
      ),
    );
  }

  Widget _buildSkillList(SkillState skillState) {
    final filteredSkills = skillState.availableSkills.where((skill) {
      final matchesCategory = _selectedCategory == 'All' || 
          skill.category == _selectedCategory;
      final matchesSearch = skill.name.toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (filteredSkills.isEmpty) {
      return const Center(child: Text('No skills found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredSkills.length,
      itemBuilder: (context, index) {
        final skill = filteredSkills[index];
        return _SkillCard(
          skill: skill,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SkillDetailScreen(skill: skill),
            ),
          ),
        );
      },
    );
  }
}

class _SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback onTap;

  const _SkillCard({required this.skill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skill.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Chip(
                label: Text(skill.category),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              LinearProgressIndicator(
                value: skill.demandLevel / 5,
                color: Theme.of(context).primaryColor,
              ),
              Text(
                '${skill.usersOffering.length} people offering',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}