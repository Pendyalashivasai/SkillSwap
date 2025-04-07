import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;

  const UserAvatar({
    Key? key,
    required this.user,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('UserAvatar: Building with imageUrl - ${user.profileImageUrl}');
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: user.profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                user.profileImageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading avatar: $error');
                  return Icon(
                    Icons.person,
                    size: radius,
                    color: Colors.grey[600],
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            ),
    );
  }
}