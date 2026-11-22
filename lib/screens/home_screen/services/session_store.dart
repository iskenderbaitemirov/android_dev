import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers WHO is logged in between app launches.
///
/// It stores one number, the user id, in shared_preferences (a small
/// key-value file). The user's data stays in the database; this is only the
/// "you are logged in as #3" note.
/// Logout = delete the note.
class SessionStore {
  static const _key = 'current_user_id';

  Future<int?> readUserId() async =>
      (await SharedPreferences.getInstance()).getInt(_key);

  Future<void> saveUserId(int id) async =>
      (await SharedPreferences.getInstance()).setInt(_key, id);

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());
