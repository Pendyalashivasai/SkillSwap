import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/models/chat_model.dart';
import 'package:skillswap/state/chat_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ChatState>(
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
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Search users...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
                ? _formatTime(chat.lastMessageTime!)
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