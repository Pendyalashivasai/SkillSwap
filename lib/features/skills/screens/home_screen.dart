import 'package:flutter/material.dart';
import 'package:skillswap/features/messaging/screens/chat_list_screen.dart';
import 'package:skillswap/features/skills/widgets/skill_card.dart';

import '../../profile/screens/profile_screen.dart';
import 'discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Track the selected tab index

  // Screens to display for each tab
  static List<Widget> _screens = [
  _HomeContent(), // Your existing home content
    const DiscoverScreen(),
    // const MatchesScreen(),
    const ChatListScreen(),
    const ProfileScreen(userId: '',),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Current selected index
        onTap: _onItemTapped, // Handle tab changes
        type: BottomNavigationBarType.fixed, // For more than 3 items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          // BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Extracted home content widget
class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Matches',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Replace with actual data
              itemBuilder: (context, index) {
                return const SkillCard(
                  skillName: 'Flutter Development',
                  userName: 'Alex Johnson',
                  matchPercentage: 85,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}