class CommentModel {
  final String userName;
  final String avatarUrl;
  final String text;
  int likeCount;
  bool isLiked;

  CommentModel({
    required this.userName,
    required this.avatarUrl,
    required this.text,
    this.likeCount = 0,
    this.isLiked = false,
  });

  void toggleLike() {
    isLiked = !isLiked;
    likeCount += isLiked ? 1 : -1;
  }
}
