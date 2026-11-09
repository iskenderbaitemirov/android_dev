import "package:android_dev/screens/content/comments_section.dart";
import "package:android_dev/screens/home_screen/models/post_model.dart";
import "package:android_dev/widgets/user_avatar.dart";
import "package:flutter/material.dart";

class PostWidget extends StatefulWidget {
  final PostModel post;
  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isLiked = false;
  // This should ideally be managed by state management

  void openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // lets the sheet move above the keyboard
      backgroundColor: Colors.white,
      builder: (context) => CommentsSection(post: widget.post),
    ).then((_) {
      // The sheet is closed: rebuild the post so the comment count updates.
      if (mounted) setState(() {});
    });
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      final current = widget.post.likeCount ?? 0;
      // Liked now -> +1, un-liked -> -1
      widget.post.addLike(isLiked ? current + 1 : current - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: author avatar + username
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                UserAvatar(url: post.avatarUrl, radius: 16),
                const SizedBox(width: 8),
                Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.imageUrl ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
                onPressed: toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: openComments,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${post.likeCount ?? 0} likes',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(post.description ?? '', style: const TextStyle(fontSize: 16.0)),
                if (post.commentCount > 0)
                  GestureDetector(
                    onTap: openComments,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'View all ${post.commentCount} comments',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
