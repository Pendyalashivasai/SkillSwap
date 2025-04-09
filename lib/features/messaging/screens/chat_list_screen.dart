import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/state/chat_state.dart';
import 'package:skillswap/state/user_state.dart';
import '../../../models/swaprequest_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../state/swaprequest_state.dart';
import '../../profile/screens/profile_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ChatTab(),
            _RequestsTab(),
          ],
        ),
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatState>(
      builder: (context, chatState, _) {
        return StreamBuilder<List<ChatModel>>(
          stream: chatState.getChatStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('ChatTab: Error loading chats - ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  chat: chat,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUserName: chat.participantDetails.values.first['name'] ?? 'Unknown',
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('_RequestsTab: Building');
    return Consumer<SwapRequestState>(
      builder: (context, requestState, _) {
        final requests = requestState.receivedRequests;
        print('_RequestsTab: Got ${requests.length} requests');

        if (requests.isEmpty) {
          print('_RequestsTab: No requests to display');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        print('_RequestsTab: Building list with ${requests.length} requests');
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            print('_RequestsTab: Building request item ${request.id}');
            return _RequestListItem(
              request: request,
              onAccept: () async {
                try {
                  await requestState.acceptRequest(request.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request accepted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              onDecline: () async {
                try {
                  await requestState.declineRequest(request.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request declined')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              onTap: () => _showUserProfile(context, request.senderId),
            );
          },
        );
      },
    );
  }

  void _showUserProfile(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => ProfileScreen(userId: userId),
      ),
    );
  }
}

class _RequestListItem extends StatelessWidget {
  final SwapRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const _RequestListItem({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(request.senderId),
      builder: (context, snapshot) {
        final sender = snapshot.data;
        if (sender == null) return const SizedBox.shrink();

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: sender.profileImageUrl != null
                ? NetworkImage(sender.profileImageUrl!)
                : null,
            child: sender.profileImageUrl == null
                ? Text(sender.name[0])
                : null,
          ),
          title: Text(sender.name),
          subtitle: Text('Wants to swap skills with you'),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  try {
                    await context.read<SwapRequestState>().acceptRequest(request.id);
                    if (context.mounted) {
                      // Navigate to chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: '${request.senderId}_${request.receiverId}',
                            otherUserName: sender.name,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  try {
                    if (request.id.isEmpty) {
                      throw Exception('Invalid request ID');
                    }
                    await context.read<SwapRequestState>().declineRequest(request.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request declined')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to decline request: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserState>().currentUserId!;
    final unreadCount = chat.unreadCounts[currentUserId] ?? 0;
    final otherUserId = chat.participants.firstWhere((id) => id != currentUserId);
    final otherUserDetails = chat.participantDetails[otherUserId];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: otherUserDetails?['profileImageUrl'] != null
            ? NetworkImage(otherUserDetails!['profileImageUrl'])
            : null,
        child: otherUserDetails?['profileImageUrl'] == null
            ? Text(otherUserDetails?['name']?[0] ?? '?')
            : null,
      ),
      title: Text(otherUserDetails?['name'] ?? 'Unknown'),
      subtitle: Text(
        chat.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unreadCount > 0 ? Badge(
        label: Text(
          unreadCount.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ) : null,
      onTap: onTap,
    );
  }
}