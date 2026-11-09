import 'package:android_dev/screens/home_screen/models/comment_model.dart';
import 'package:android_dev/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class CommentWidget extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onLikeTap;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(url: comment.avatarUrl, radius: 18),
      title: Text(
        comment.userName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(comment.text),
      trailing: GestureDetector(
        onTap: onLikeTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              comment.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: comment.isLiked ? Colors.red : Colors.grey,
            ),
            if (comment.likeCount > 0)
              Text('${comment.likeCount}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
