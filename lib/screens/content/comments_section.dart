import 'package:android_dev/screens/content/comment_widget.dart';
import 'package:android_dev/screens/home_screen/models/comment_model.dart';
import 'package:android_dev/screens/home_screen/models/post_model.dart';
import 'package:flutter/material.dart';

/// The content of the comments bottom sheet for ONE post.
///
/// It's a StatefulWidget because the bottom sheet is a separate route:
/// calling setState in PostWidget would NOT rebuild the sheet.
/// This widget has its own State, so its setState redraws the list.
class CommentsSection extends StatefulWidget {
  final PostModel post;
  const CommentsSection({super.key, required this.post});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  // A controller lets us read and clear the TextField.
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // controllers must be disposed (lifecycle, week 5)
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.post.addComment(
        CommentModel(
          userName: 'me',
          avatarUrl: 'https://randomuser.me/api/portraits/men/60.jpg',
          text: text,
        ),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;
    return Padding(
      // Moves the sheet up when the keyboard opens.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Comments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: comments.isEmpty
                  ? const Center(child: Text('No comments yet. Be the first!'))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) => CommentWidget(
                        comment: comments[index],
                        onLikeTap: () => setState(() => comments[index].toggleLike()),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Add a comment...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
