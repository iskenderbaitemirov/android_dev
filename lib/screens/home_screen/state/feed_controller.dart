import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/posts_repository.dart';
import 'auth_controller.dart';

// ── READ ─────────────────────────────────────────────────────────────────────

/// All posts as seen by the logged-in user.
/// Watches currentUserIdProvider, so it reloads when another user logs in
/// (then `isLiked` is calculated for the new user).
final feedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(postsRepositoryProvider).watchFeed(userId);
});

/// Comments of one post: `commentsProvider(postId)`.
/// autoDispose = stop watching when the comments sheet closes.
final commentsProvider = StreamProvider.autoDispose.family<List<CommentModel>, int>(
  (ref, postId) => ref.watch(postsRepositoryProvider).watchComments(postId),
);

// ── WRITE ────────────────────────────────────────────────────────────────────

/// Actions. Each one adds "who is doing it" (the logged-in user) and calls
/// the repository. The UI updates by itself because the streams above re-run.
class FeedController extends Notifier<void> {
  @override
  void build() {}

  PostsRepository get _repo => ref.read(postsRepositoryProvider);
  int get _userId => ref.read(currentUserIdProvider)!; // only used when logged in

  Future<void> toggleLike(int postId) => _repo.toggleLike(_userId, postId);

  Future<void> createPost(String imageUrl, String caption) =>
      _repo.createPost(_userId, imageUrl, caption);

  Future<void> addComment(int postId, String body) =>
      _repo.addComment(postId, _userId, body);

  Future<void> deleteComment(int commentId) =>
      _repo.deleteComment(commentId, _userId);
}

final feedControllerProvider =
    NotifierProvider<FeedController, void>(FeedController.new);
