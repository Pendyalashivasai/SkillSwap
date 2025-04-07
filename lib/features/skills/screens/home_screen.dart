import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/features/messaging/screens/chat_list_screen.dart';
import 'package:skillswap/features/skills/widgets/skill_card.dart';
import 'package:skillswap/state/user_state.dart';
import 'package:skillswap/features/profile/screens/profile_screen.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../profile/widget/userprofilesheet.dart';
import '../widgets/userskillcard.dart';
import 'discover_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load user data when HomeScreen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = context.read<UserState>();
      if (userState.currentUser == null && userState.currentUserId != null) {
        userState.loadCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, _) {
        if (userState.currentUserId == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final List<Widget> screens = [
          const _HomeContent(),
          const DiscoverScreen(),
          const ChatListScreen(),
          ProfileScreen(userId: userState.currentUserId!),
        ];

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = FirestoreService().getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: () => setState(() {
        //       _usersFuture = FirestoreService().getAllUsers();
        //     }),
        //   ),
        // ],
      ),
      body: Consumer<UserState>(
        builder: (context, userState, _) {
          if (userState.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<List<UserModel>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final users = snapshot.data ?? [];
              // Filter out current user
              final otherUsers = users.where((u) => u.id != userState.currentUser?.id).toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: otherUsers.length,
                        itemBuilder: (context, index) {
                          final user = otherUsers[index];
                          return UserSkillCard(
                            user: user,
                            onTap: () => _showUserProfile(context, user),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUserProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => UserProfileSheet(
          user: user,
          onSwapRequested: () => _requestSwap(context, user),
        ),
      ),
    );
  }

  Future<void> _requestSwap(BuildContext context, UserModel otherUser) async {
    final currentUser = context.read<UserState>().currentUser;
    if (currentUser == null) return;

    try {
      await FirestoreService().createSwapRequest(
        senderId: currentUser.id,
        receiverId: otherUser.id,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap request sent!')),
        );
        Navigator.pop(context); // Close profile sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}