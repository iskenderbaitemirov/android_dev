import 'package:android_dev/core/db/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_repository.dart';
import '../services/session_store.dart';

/// The SINGLE source of truth for "who is logged in".
///
/// State type `User?`:
///   AsyncLoading     → app just started, still reading the saved session
///   AsyncData(null)  → nobody logged in → show the login screen
///   AsyncData(user)  → logged in        → show the app
///
/// Every other provider that needs the user watches this one, so on login,
/// logout or account switch they ALL recompute automatically.
class AuthController extends AsyncNotifier<User?> {
  /// Runs once at startup: "was someone already logged in last time?"
  @override
  Future<User?> build() async {
    final userId = await ref.read(sessionStoreProvider).readUserId();
    if (userId == null) return null;

    final user = await ref.read(authRepositoryProvider).getUser(userId);
    // The id is saved but the user is gone (e.g. DB was reset) → forget it.
    if (user == null) await ref.read(sessionStoreProvider).clear();
    return user;
  }

  /// Throws [AuthException] on a wrong password. The login screen catches it
  /// and shows the message. State only changes on success.
  Future<void> login(String username, String password) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(username: username, password: password);
    await _startSession(user);
  }

  Future<void> register(String username, String password) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(username: username, password: password);
    await _startSession(user); // log straight in after registering
  }

  Future<void> logout() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> _startSession(User user) async {
    await ref.read(sessionStoreProvider).saveUserId(user.id);
    state = AsyncData(user);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

/// Shortcut: just the id of the logged-in user (null = logged out).
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider).value?.id,
);

/// A user's row, live from the DB (updates after "Edit profile").
final userProvider = StreamProvider.family<User?, int>(
  (ref, id) => ref.watch(authRepositoryProvider).watchUser(id),
);
