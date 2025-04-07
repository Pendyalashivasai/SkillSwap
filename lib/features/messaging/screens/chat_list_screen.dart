import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/state/chat_state.dart';
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
        if (chatState.chats.isEmpty) {
          return const Center(child: Text('No conversations yet'));
        }
        return ListView.builder(
          itemCount: chatState.chats.length,
          itemBuilder: (context, index) {
            final chat = chatState.chats[index];
            return _ChatListItem(
              chat: chat,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: chat.id),
                ),
              ),
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
    return Consumer<SwapRequestState>(
      builder: (context, requestState, _) {
        if (requestState.receivedRequests.isEmpty) {
          return const Center(child: Text('No pending requests'));
        }
        return ListView.builder(
          itemCount: requestState.receivedRequests.length,
          itemBuilder: (context, index) {
            final request = requestState.receivedRequests[index];
            return _RequestListItem(
              request: request,
              onAccept: () => requestState.acceptRequest(request.id),
              onDecline: () => requestState.declineRequest(request.id),
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
                    if (request.id.isEmpty) {
                      throw Exception('Invalid request ID');
                    }
                    await context.read<SwapRequestState>().acceptRequest(request.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request accepted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to accept request: $e')),
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
  final Chat chat;
  final VoidCallback onTap;

  const _ChatListItem({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: chat.participantAvatar != null
            ? NetworkImage(chat.participantAvatar!)
            : null,
      ),
      title: Text(chat.participantName),
      subtitle: Text(
        chat.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chat.lastMessageTime != null
                ? _formatTime(chat.lastMessageTime)
                : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (chat.unreadCount > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}