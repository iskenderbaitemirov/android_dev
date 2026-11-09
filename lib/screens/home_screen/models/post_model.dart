import 'package:android_dev/screens/home_screen/models/comment_model.dart';

class PostModel {
  final String userName;
  final String avatarUrl;
  final String? imageUrl;
  int? likeCount;
  final String? description;

  final List<CommentModel> comments;

  PostModel({
    required this.userName,
    required this.avatarUrl,
    this.imageUrl,
    this.likeCount,
    this.description,
    List<CommentModel>? comments,
  }) : comments = comments ?? [];
  int get commentCount => comments.length;

  void addLike(int newCount) {
    likeCount = newCount;
  }

  void addComment(CommentModel comment) {
    comments.add(comment);
  }
}
