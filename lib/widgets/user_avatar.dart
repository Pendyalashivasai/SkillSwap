import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillswap/services/firestore_service.dart';
import 'package:skillswap/state/user_state.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserAvatarUrl(context),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        return GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            backgroundImage: imageUrl != null
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: imageUrl == null
                ? Icon(
                    Icons.person,
                    size: radius,
                    color: Colors.grey[600],
                  )
                : null,
          ),
        );
      },
    );
  }

  Future<String?> _getUserAvatarUrl(BuildContext context) async {
    try {
      // First try to get from current state
      final userState = context.read<UserState>();
      if (userState.currentUser?.id == userId) {
        return userState.currentUser?.profileImageUrl;
      }

      // Fallback to Firestore lookup
      final user = await FirestoreService().getUser(userId);
      return user?.profileImageUrl;
    } catch (e) {
      debugPrint('Error getting user avatar: $e');
      return null;
    }
  }
}