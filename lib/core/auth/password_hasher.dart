import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// We NEVER store the password itself, only `sha256(salt + password)`.
///
/// * **Hash**: a one-way function. You can't turn the hash back into the
///   password, but hashing the same input always gives the same output, so
///   at login we hash what the user typed and compare it with the stored hash.
/// * **Salt**: random bytes, different for every user. Two users with the
///   password "123456" still get different hashes, and pre-computed
///   "rainbow tables" of common passwords stop working.
///
/// Lab-level security: a real app checks passwords on a server and uses a
/// slow hash (bcrypt / argon2) designed for passwords.
String generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword(String password, String salt) =>
    sha256.convert(utf8.encode('$salt:$password')).toString();
