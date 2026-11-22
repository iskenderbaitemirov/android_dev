/// What the UI needs to draw one post.
///
/// This is NOT the drift row class `Post`: a feed item also needs the author's
/// name and avatar (from `users`) and likeCount / commentCount / isLiked
/// (computed from `likes` and `comments`). The repository builds it with
/// one SQL query.
class PostModel {
  final int id;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  /// Did the CURRENTLY LOGGED-IN user like this post?
  final bool isLiked;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });
}
