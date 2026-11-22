import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:android_dev/screens/home_screen/services/auth_repository.dart';
import 'package:android_dev/screens/home_screen/services/posts_repository.dart';
import 'package:android_dev/screens/home_screen/state/auth_controller.dart';
import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fresh, empty DB in RAM for every test. No file, no demo data.
AppDatabase memoryDb() =>
    AppDatabase(executor: NativeDatabase.memory(), seedDemoData: false);

void main() {
  // Each test opens its own in-memory DB on purpose; silence drift's warning.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late AuthRepository auth;
  late PostsRepository posts;

  setUp(() {
    db = memoryDb();
    auth = AuthRepository(db);
    posts = PostsRepository(db);
  });
  tearDown(() => db.close());

  group('AuthRepository', () {
    test('register stores a hash, never the plain password', () async {
      final user = await auth.register(username: 'Alice', password: 'secret1');
      expect(user.username, 'alice'); // normalised to lower case
      expect(user.passwordHash, isNot('secret1'));
      expect(user.salt, isNotEmpty);
    });

    test('duplicate username is rejected', () async {
      await auth.register(username: 'alice', password: 'secret1');
      expect(
        () => auth.register(username: 'ALICE', password: 'other12'),
        throwsA(isA<AuthException>()),
      );
    });

    test('login: right password works, wrong password fails', () async {
      await auth.register(username: 'alice', password: 'secret1');
      final user = await auth.login(username: 'alice', password: 'secret1');
      expect(user.username, 'alice');
      expect(
        () => auth.login(username: 'alice', password: 'WRONG'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.login(username: 'nobody', password: 'secret1'),
        throwsA(isA<AuthException>()),
      );
    });

    test('short password / bad username are rejected', () async {
      expect(() => auth.register(username: 'bob', password: '123'),
          throwsA(isA<AuthException>()));
      expect(() => auth.register(username: 'a b', password: 'secret1'), // space
          throwsA(isA<AuthException>()));
    });
  });

  group('Likes and comments are per user', () {
    test('A likes → B sees count 1 but isLiked false', () async {
      final a = await auth.register(username: 'alice', password: 'secret1');
      final b = await auth.register(username: 'bob', password: 'secret1');
      final postId = await posts.createPost(b.id, 'https://x/img.jpg', 'hi');

      await posts.toggleLike(a.id, postId);

      final asA = (await posts.watchFeed(a.id).first).single;
      final asB = (await posts.watchFeed(b.id).first).single;
      expect(asA.likeCount, 1);
      expect(asA.isLiked, isTrue);
      expect(asB.likeCount, 1);
      expect(asB.isLiked, isFalse);

      // toggle again = unlike
      await posts.toggleLike(a.id, postId);
      final after = (await posts.watchFeed(a.id).first).single;
      expect(after.likeCount, 0);
      expect(after.isLiked, isFalse);
    });

    test('isLiked filter = only posts THIS user liked', () async {
      final a = await auth.register(username: 'alice', password: 'secret1');
      final b = await auth.register(username: 'bob', password: 'secret1');
      final p1 = await posts.createPost(a.id, 'u', '1');
      await posts.createPost(a.id, 'u', '2');
      await posts.toggleLike(b.id, p1);

      // Same filter the Activity tab uses.
      final likedByB = (await posts.watchFeed(b.id).first).where((p) => p.isLiked);
      final likedByA = (await posts.watchFeed(a.id).first).where((p) => p.isLiked);
      expect(likedByB.map((p) => p.id), [p1]);
      expect(likedByA, isEmpty);
    });

    test('comments carry the author name; only the author can delete', () async {
      final a = await auth.register(username: 'alice', password: 'secret1');
      final b = await auth.register(username: 'bob', password: 'secret1');
      final postId = await posts.createPost(a.id, 'u', 'c');

      await posts.addComment(postId, a.id, 'first');
      final bobCommentId =
          await posts.addComment(postId, b.id, 'second');

      var comments = await posts.watchComments(postId).first;
      expect(comments.map((c) => c.authorName), ['alice', 'bob']);
      expect((await posts.watchFeed(a.id).first).single.commentCount, 2);

      // Alice tries to delete Bob's comment: nothing happens.
      await posts.deleteComment(bobCommentId, a.id);
      expect(await posts.watchComments(postId).first, hasLength(2));

      // Bob deletes his own.
      await posts.deleteComment(bobCommentId, b.id);
      comments = await posts.watchComments(postId).first;
      expect(comments.map((c) => c.body), ['first']);
    });

    test('the feed stream re-emits after a like (readsFrom works)', () async {
      final a = await auth.register(username: 'alice', password: 'secret1');
      final postId = await posts.createPost(a.id, 'u', 'c');

      final counts = posts
          .watchFeed(a.id)
          .map((list) => list.single.likeCount)
          .take(2)
          .toList();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await posts.toggleLike(a.id, postId);
      expect(await counts, [0, 1]);
    });

    test('foreign keys: a post for a missing user is rejected', () async {
      // Read once so the DB opens and beforeOpen turns foreign keys on.
      final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(fk.read<int>('foreign_keys'), 1);
      expect(
        () => posts.createPost(999, 'u', 'c'),
        throwsA(anything),
      );
    });
  });

  group('AuthController (session + Riverpod)', () {
    test('register → logged in, logout → null, restart → still logged in', () async {
      SharedPreferences.setMockInitialValues({});
      final testDb = memoryDb();
      ProviderContainer makeContainer() => ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(testDb)],
          );

      var container = makeContainer();
      expect(await container.read(authControllerProvider.future), isNull);

      await container.read(authControllerProvider.notifier).register('alice', 'secret1');
      expect(container.read(currentUserIdProvider), isNotNull);

      // "Restart the app": new container, same prefs + DB → session restored.
      container.dispose();
      container = makeContainer();
      final restored = await container.read(authControllerProvider.future);
      expect(restored?.username, 'alice');

      await container.read(authControllerProvider.notifier).logout();
      expect(container.read(currentUserIdProvider), isNull);

      container.dispose();
      await testDb.close();
    });
  });

  test('upgrade from the old v1 database drops old tables and seeds v2', () async {
    // `setup` runs on the raw SQLite connection BEFORE drift checks the
    // version, so this fakes a phone that still has the old v1 file.
    final upgraded = AppDatabase(
      executor: NativeDatabase.memory(setup: (raw) {
        raw.execute('CREATE TABLE cached_posts (id TEXT PRIMARY KEY)');
        raw.execute('CREATE TABLE user_profiles (id TEXT PRIMARY KEY)');
        raw.execute('CREATE TABLE post_comments (id TEXT PRIMARY KEY)');
        raw.execute('PRAGMA user_version = 1');
      }),
    );

    final tables = await upgraded
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r.read<String>('name'))
        .get();
    expect(tables, containsAll(['users', 'posts', 'likes', 'comments']));
    expect(tables, isNot(contains('cached_posts'))); // proves onUpgrade ran
    expect(tables, isNot(contains('user_profiles')));
    expect(tables, isNot(contains('post_comments')));

    final user = await AuthRepository(upgraded)
        .login(username: 'aibek.travels', password: 'password');
    expect(user.username, 'aibek.travels');
    await upgraded.close();
  });

  test('demo data is seeded on a fresh install', () async {
    final seeded = AppDatabase(executor: NativeDatabase.memory());
    final count = await seeded
        .customSelect('SELECT COUNT(*) AS n FROM users',
            variables: const <Variable<Object>>[])
        .map((r) => r.read<int>('n'))
        .getSingle();
    expect(count, 2);
    // and the demo password is "password"
    final user = await AuthRepository(seeded).login(username: 'aizada_k', password: 'password');
    expect(user.username, 'aizada_k');
    await seeded.close();
  });

}
