import 'package:flutter/material.dart';

/// Round avatar used everywhere (stories, post header, comments).
///
/// CircleAvatar gives the round shape; Image.network loads the photo.
/// errorBuilder runs if the image can't load (no internet, blocked site,
/// broken link) and shows a person icon instead of throwing an exception.
class UserAvatar extends StatelessWidget {
  final String url;
  final double radius;

  const UserAvatar({super.key, required this.url, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.person, size: radius, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
