import 'package:android_dev/core/auth/password_hasher.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TABLES
//
//   users 1 ──< posts          one user writes many posts
//   users 1 ──< comments >── 1 posts
//   users 1 ──< likes    >── 1 posts   (likes = "junction" table, many-to-many)
//
// Every class below becomes a SQL table. drift turns the class name into the
// table name (Users → users) and generates a row class (Users → User).
// After changing anything here run:  dart run build_runner build -d
// ─────────────────────────────────────────────────────────────────────────────

class Users extends Table {
  // autoIncrement() also makes this the primary key: 1, 2, 3, ...
  IntColumn get id => integer().autoIncrement()();
  // unique() → SQLite itself refuses a second user with the same name.
  TextColumn get username => text().withLength(min: 3, max: 30).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // references() = FOREIGN KEY. The post must belong to an existing user.
  // onDelete: cascade → deleting the user deletes their posts too.
  IntColumn get authorId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageUrl => text()();
  TextColumn get caption => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row = "user X likes post Y".
/// There is NO likeCount / isLiked column anywhere: we compute them with
/// COUNT(*) and EXISTS(...). That way every user has their own likes, and
/// the count can never get out of sync.
class Likes extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get postId =>
      integer().references(Posts, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Composite primary key: the PAIR (userId, postId) must be unique,
  // so the same user can't like the same post twice.
  @override
  Set<Column<Object>> get primaryKey => {userId, postId};
}

class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get postId =>
      integer().references(Posts, #id, onDelete: KeyAction.cascade)();
  IntColumn get authorId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text().withLength(min: 1, max: 500)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─────────────────────────────────────────────────────────────────────────────
// DATABASE
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Users, Posts, Likes, Comments])
class AppDatabase extends _$AppDatabase {
  /// [executor] lets tests pass `NativeDatabase.memory()` (a throw-away DB in
  /// RAM). The app passes nothing and gets the real file `social_app`.
  AppDatabase({QueryExecutor? executor, this.seedDemoData = true})
      : super(executor ?? driftDatabase(name: 'social_app'));

  final bool seedDemoData;

  // v1 = old CachedPosts/UserProfiles tables, v2 = the tables above.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Fresh install: no DB file yet.
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        // The phone still has a v1 file from the old build.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // The old tables had no users, so they can't be converted
            // into the new shape. They only held demo data → drop them.
            await customStatement('DROP TABLE IF EXISTS cached_posts');
            await customStatement('DROP TABLE IF EXISTS user_profiles');
            await customStatement('DROP TABLE IF EXISTS post_comments');
            await m.createAll();
            await _seed();
          }
        },
        // Runs every time the DB opens. SQLite ignores FOREIGN KEYs
        // unless you turn them on for each connection.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Two demo accounts (password: `password`) and a few posts, so the feed
  /// isn't empty and you can log in as two people to test per-user likes.
  Future<void> _seed() async {
    if (!seedDemoData) return;

    Future<int> addUser(String name, String avatar, String bio) {
      final salt = generateSalt();
      return into(users).insert(UsersCompanion.insert(
        username: name,
        passwordHash: hashPassword('password', salt),
        salt: salt,
        avatarUrl: Value(avatar),
        bio: Value(bio),
      ));
    }

    final aibek = await addUser('aibek.travels',
        'https://randomuser.me/api/portraits/men/11.jpg', 'Travel & mountains');
    final aizada = await addUser('aizada_k',
        'https://randomuser.me/api/portraits/women/5.jpg', 'Coffee and code');

    await batch((b) => b.insertAll(posts, [
          PostsCompanion.insert(
            authorId: aibek,
            imageUrl: 'https://picsum.photos/id/1018/800/800',
            caption: 'Sunrise over the mountains. Worth waking up at 5 am',
          ),
          PostsCompanion.insert(
            authorId: aizada,
            imageUrl: 'https://picsum.photos/id/1060/800/800',
            caption: 'Morning coffee before the lab',
          ),
          PostsCompanion.insert(
            authorId: aibek,
            imageUrl: 'https://picsum.photos/id/1043/800/800',
            caption: 'Autumn in the city',
          ),
        ]));
  }
}
