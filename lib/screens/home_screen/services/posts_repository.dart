import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment_model.dart';
import '../models/post_model.dart';

/// Posts, likes and comments in the database.
/// Reading = SQL + `.watch()` (a Stream that updates itself).
/// Writing = drift's insert / delete.
class PostsRepository {
  PostsRepository(this._db);

  final AppDatabase _db;

  // ── POSTS ──────────────────────────────────────────────────────────────────

  /// All posts, newest first, with author info and like/comment numbers.
  /// [viewerId] = the logged-in user, needed for `is_liked`.
  Stream<List<PostModel>> watchFeed(int viewerId) {
    const sql = '''
      SELECT p.id, p.author_id, p.image_url, p.caption, p.created_at,
             u.username   AS author_name,
             u.avatar_url AS author_avatar,
             (SELECT COUNT(*) FROM likes    WHERE post_id = p.id) AS like_count,
             (SELECT COUNT(*) FROM comments WHERE post_id = p.id) AS comment_count,
             EXISTS (SELECT 1 FROM likes
                     WHERE post_id = p.id AND user_id = ?)        AS is_liked
      FROM posts p
      JOIN users u ON u.id = p.author_id
      ORDER BY p.created_at DESC, p.id DESC
    ''';

    return _db
        .customSelect(
          sql,
          variables: [Variable.withInt(viewerId)], // fills the `?`
          // Tells drift which tables this SQL reads, so the stream
          // re-runs when any of them changes (e.g. someone likes a post).
          readsFrom: {_db.posts, _db.users, _db.likes, _db.comments},
        )
        .watch()
        .map((rows) => rows
            .map((row) => PostModel(
                  id: row.read<int>('id'),
                  authorId: row.read<int>('author_id'),
                  authorName: row.read<String>('author_name'),
                  authorAvatarUrl: row.readNullable<String>('author_avatar'),
                  imageUrl: row.read<String>('image_url'),
                  caption: row.read<String>('caption'),
                  createdAt: row.read<DateTime>('created_at'),
                  likeCount: row.read<int>('like_count'),
                  commentCount: row.read<int>('comment_count'),
                  isLiked: row.read<int>('is_liked') == 1, // SQLite: 0 / 1
                ))
            .toList());
  }

  Future<int> createPost(int authorId, String imageUrl, String caption) =>
      _db.into(_db.posts).insert(PostsCompanion.insert(
            authorId: authorId,
            imageUrl: imageUrl,
            caption: caption,
          ));

  // ── LIKES ──────────────────────────────────────────────────────────────────

  /// Already liked → remove the like. Not liked → add it.
  Future<void> toggleLike(int userId, int postId) async {
    final existing = await (_db.select(_db.likes)
          ..where((l) => l.userId.equals(userId) & l.postId.equals(postId)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.delete(_db.likes)
            ..where((l) => l.userId.equals(userId) & l.postId.equals(postId)))
          .go();
    } else {
      await _db
          .into(_db.likes)
          .insert(LikesCompanion.insert(userId: userId, postId: postId));
    }
  }

  // ── COMMENTS ───────────────────────────────────────────────────────────────

  /// Comments of one post, oldest first, with the author's name and avatar.
  Stream<List<CommentModel>> watchComments(int postId) {
    const sql = '''
      SELECT c.id, c.post_id, c.author_id, c.body, c.created_at,
             u.username AS author_name, u.avatar_url AS author_avatar
      FROM comments c
      JOIN users u ON u.id = c.author_id
      WHERE c.post_id = ?
      ORDER BY c.created_at, c.id
    ''';

    return _db
        .customSelect(
          sql,
          variables: [Variable.withInt(postId)],
          readsFrom: {_db.comments, _db.users},
        )
        .watch()
        .map((rows) => rows
            .map((row) => CommentModel(
                  id: row.read<int>('id'),
                  postId: row.read<int>('post_id'),
                  authorId: row.read<int>('author_id'),
                  authorName: row.read<String>('author_name'),
                  authorAvatarUrl: row.readNullable<String>('author_avatar'),
                  body: row.read<String>('body'),
                  createdAt: row.read<DateTime>('created_at'),
                ))
            .toList());
  }

  Future<int> addComment(int postId, int authorId, String body) =>
      _db.into(_db.comments).insert(CommentsCompanion.insert(
            postId: postId,
            authorId: authorId,
            body: body,
          ));

  /// The WHERE also checks the author, so you can only delete your own.
  Future<void> deleteComment(int commentId, int userId) => (_db.delete(_db.comments)
        ..where((c) => c.id.equals(commentId) & c.authorId.equals(userId)))
      .go();
}

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepository(ref.watch(databaseProvider)),
);
