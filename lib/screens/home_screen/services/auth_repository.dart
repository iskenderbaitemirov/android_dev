import 'package:android_dev/core/auth/password_hasher.dart';
import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A "normal" error the UI shows to the user ("Wrong password"),
/// as opposed to a bug.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Everything about accounts in the DATABASE: create, check password, read,
/// update. It does NOT remember who is logged in; that's the session's job
/// (see session_store.dart).
class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;

  Future<User> register({required String username, required String password}) async {
    // Normalise so "Aibek" and "aibek" count as the same name.
    final name = username.trim().toLowerCase();

    if (name.length < 3 || name.length > 30 || name.contains(' ')) {
      throw const AuthException('Username: 3–30 characters, no spaces.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    if (await _findByUsername(name) != null) {
      throw const AuthException('This username is already taken.');
    }

    final salt = generateSalt();
    final id = await _db.into(_db.users).insert(UsersCompanion.insert(
          username: name,
          passwordHash: hashPassword(password, salt),
          salt: salt,
        ));
    return (await getUser(id))!;
  }

  Future<User> login({required String username, required String password}) async {
    final user = await _findByUsername(username.trim().toLowerCase());
    // Same message for "no such user" and "wrong password", so nobody can
    // use the login form to find out which usernames exist.
    if (user == null || hashPassword(password, user.salt) != user.passwordHash) {
      throw const AuthException('Wrong username or password.');
    }
    return user;
  }

  Future<User?> getUser(int id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

  /// A Stream: emits again whenever this user's row changes (e.g. after
  /// editing the profile), so the profile screen updates by itself.
  Stream<User?> watchUser(int id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).watchSingleOrNull();

  Future<void> updateProfile(int id, {String? avatarUrl, String? bio}) =>
      (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(avatarUrl: Value(avatarUrl), bio: Value(bio)),
      );

  Future<User?> _findByUsername(String name) =>
      (_db.select(_db.users)..where((u) => u.username.equals(name)))
          .getSingleOrNull();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(databaseProvider)),
);
