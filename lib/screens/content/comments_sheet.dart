import 'package:android_dev/screens/home_screen/state/auth_controller.dart';
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    // No author here: the controller adds the logged-in user.
    await ref
        .read(feedControllerProvider.notifier)
        .addComment(widget.postId, body);
    _controller.clear();
  }

  Future<void> _confirmDelete(int commentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(feedControllerProvider.notifier).deleteComment(commentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    final myId = ref.watch(currentUserIdProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: comments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Could not load comments: $error')),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('Be the first to comment.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final comment = items[index];
                          final isMine = comment.authorId == myId;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: comment.authorAvatarUrl == null
                                  ? null
                                  : NetworkImage(comment.authorAvatarUrl!),
                              child: comment.authorAvatarUrl == null
                                  ? Text(comment.authorName[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(comment.authorName),
                            subtitle: Text(comment.body),
                            // Only your own comments get a delete button.
                            trailing: isMine
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(comment.id),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 500,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(hintText: 'Add a comment...', counterText: ''),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _submit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
