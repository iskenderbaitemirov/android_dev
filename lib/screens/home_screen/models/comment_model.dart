/// A comment plus its author's name/avatar (joined from `users`).
class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
}
