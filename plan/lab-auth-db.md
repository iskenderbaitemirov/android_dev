# Lab: DB tables for users & posts, registration / login / logout, likes & comments in the DB

> Task (from class): *улучшить ДБ таблицы для постов и юзеров, добавить регистрацию и выход/вход аккаунта, привязать лайки и комментарии к базе данных.*
> In English: improve the DB tables for posts and users, add registration and log in / log out, and store likes and comments in the database.

Branch: `lab-auth-db` (built on `updated-database-branch`).

---

## 0. What was wrong before

| Before (`updated-database-branch`) | Problem |
|---|---|
| `UserProfiles(id, nickname, avatarUrl)` | No password, no unique username. You can't log in with this. |
| `CachedPosts.authorId` = text `'me'`, `authorName` = `'alimhan'` | Every post belongs to one hard-coded fake user. |
| `CachedPosts.isLiked` (one bool per post) | A like isn't tied to a **person**. If A likes a post, B sees it as liked too. |
| `CachedPosts.likes` (a stored counter) | It can drift out of sync with reality. |
| Comments: raw `CREATE TABLE` in a string + a manual `StreamController` | drift doesn't know this table exists, so no type safety and no `.watch()`. |
| Nothing remembers who is logged in | No session, so no login or logout. |

---

## 1. The big picture (layers)

```
 ┌──────────── UI (widgets) ────────────┐
 │ AuthScreen  HomeTab  ProfileTab ...  │   ref.watch(...)  → read data
 └───────────────┬──────────────────────┘   ref.read(...notifier).action() → write
                 │
 ┌──────── State (Riverpod) ────────────┐
 │ authControllerProvider  (who am I?)  │ ◄── ONE source of truth for the user
 │ feedPostsProvider, commentsProvider… │     everything else watches it
 │ feedControllerProvider  (actions)    │
 └───────────────┬──────────────────────┘
                 │
 ┌──────── Data (repositories) ─────────┐
 │ AuthRepository   PostsRepository     │  SQL lives ONLY here
 │ SessionStore (shared_preferences)    │
 └───────────────┬──────────────────────┘
                 │
          drift  →  SQLite file "social_app"
```

Rule: **widgets never touch the database.** They talk to providers, providers call repositories, and repositories talk to drift.

---

## 2. The schema: the most important part

```
users                     posts                     comments
─────────────             ─────────────             ─────────────
id        PK  ◄──┐        id        PK  ◄──┐  ┌──►  id        PK
username  UNIQUE │        author_id FK ────┘  │     post_id   FK → posts
password_hash    ├─────── (who wrote it)      │     author_id FK → users
salt             │        image_url           │     body
avatar_url       │        caption             │     created_at
bio              │        created_at          │
created_at       │                            │
                 │        likes  (junction)   │
                 │        ─────────────       │
                 └─────── user_id  FK ┐ PK    │
                          post_id  FK ┘(pair)─┘
                          created_at
```

File: `lib/core/db/app_database.dart`

### Why each decision (the teacher may ask about any of these)

1. **`id` is an `int autoIncrement`**: SQLite hands out 1, 2, 3... Before, ids were strings like `'post-1731…'` built by hand.
2. **`username ... .unique()`**: the **database** guarantees no two users share a name. We also check in Dart to show a nice message, but the constraint is the real guard.
3. **`passwordHash` + `salt`, never the password.** See §3.
4. **`authorId ... .references(Users, #id)`** is a **foreign key**. A post can't point to a user that doesn't exist. `onDelete: KeyAction.cascade`: delete a user and their posts, likes and comments go too.
5. **`Likes` is a separate table (a *junction* / *many-to-many* table).**
   One user likes many posts, and one post is liked by many users. That's many-to-many, and in SQL it's always a third table with two FKs.
   - `likeCount` = `SELECT COUNT(*) FROM likes WHERE post_id = ?`
   - `isLiked` (for me) = `EXISTS (SELECT 1 FROM likes WHERE post_id = ? AND user_id = <me>)`
   - We **don't store** these numbers, we **compute** them, so they can't get out of sync.
6. **Composite primary key `{userId, postId}`**: the pair must be unique, so you can't like the same post twice even if a bug tries.
7. **`Comments` is a real drift table**, so it gets generated classes, type checks and `.watch()` for free.
8. **`PRAGMA foreign_keys = ON` in `beforeOpen`**: SQLite **ignores** FKs by default. You must switch them on for every connection.

### Migration (schemaVersion 1 → 2)

Phones that ran the old build already have a v1 database file. `onCreate` does **not** run for them; `onUpgrade` does.
The old tables have no users, so they can't be converted. They only held demo data, so we `DROP` them and `createAll()`.
(With real user data you'd write `ALTER TABLE` / `m.addColumn(...)` steps instead. Never delete real data.)

After changing tables **always** run:
```bash
dart run build_runner build -d
```
That regenerates `app_database.g.dart` (the `User`, `Post`, `UsersCompanion`... classes).

---

## 3. Passwords: hash + salt

File: `lib/core/auth/password_hasher.dart`

- **Hash** (`sha256`) is one-way: `"secret1"` becomes `"9f86d0…"`, and you can't go back.
- **Login** = hash what the user typed with the same salt and compare it with the stored hash.
- **Salt** = random bytes, different per user, stored next to the hash. Two users with the same password get different hashes, which defeats pre-computed tables of common passwords.
- Same error for "no such user" and "wrong password", so the form doesn't reveal which usernames exist.
- Honest note: real apps check passwords **on a server** with a **slow** hash (bcrypt/argon2). A local-only login is fine for this lab.

---

## 4. Session: "who is logged in?"

Two different things, two different storages:

| What | Where | Why |
|---|---|---|
| Accounts, posts, likes, comments | SQLite (drift) | Relational data with FKs |
| "Currently logged in as user #3" | `shared_preferences` (`SessionStore`) | Just one number. Logout = delete it |

### `AuthController` (`lib/screens/home_screen/state/auth_controller.dart`)
An `AsyncNotifier<User?>`:

| State | Meaning | AuthGate shows |
|---|---|---|
| `AsyncLoading` | app starting, reading the saved id | spinner |
| `AsyncData(null)` | logged out | `AuthScreen` |
| `AsyncData(user)` | logged in | `MainScreen` |

- `build()` runs at start: read the saved id, then load that user from the DB. This is "stay logged in after restart".
- `login()` / `register()`: call the repository (which throws `AuthException` on errors), save the id, `state = AsyncData(user)`.
- `logout()`: clear the id, `state = AsyncData(null)`.

### `AuthGate` (`lib/main.dart`)
```dart
auth.when(
  loading: ...spinner,
  data: (user) => user == null ? AuthScreen() : MainScreen(key: ValueKey(user.id)),
)
```
Login and logout code **never call Navigator**. They only change state, and the gate reacts.
`ValueKey(user.id)`: when a different person logs in, Flutter builds a brand-new `MainScreen`. Otherwise `AnimatedIndexedStack` would keep the old user's tabs alive.

Why are login and register **one screen** with a toggle? If you `Navigator.push` a RegisterScreen and registration succeeds, the gate swaps its child, but the pushed route stays **on top**. One screen avoids that bug.

---

## 5. Likes & comments tied to the user

### Reading: streams all the way up
```
widget ── ref.watch(feedPostsProvider)
            └─ ref.watch(currentUserIdProvider)          ← re-runs when user changes
            └─ repository.watchFeed(me)
                 └─ drift customSelect(...).watch()       ← re-runs after any write
```
- Tap like → `INSERT INTO likes` → drift sees the table changed → the query runs again → the stream emits → Riverpod rebuilds the heart. **We never update the UI by hand.**
- **`readsFrom: {posts, users, likes, comments}`** on the hand-written SQL: drift can't parse your string to see which tables it uses. Forget this and the like count **won't update**. The test `the feed stream re-emits after a like` guards it.
- Comments work the same way: one SQL query with a `JOIN users`, plus `.watch()` and `readsFrom`.
- **Only one posts query.** Profile and Activity don't have their own SQL; they filter the feed list in Dart:
  - Profile: `allPosts.where((p) => p.authorId == myId)`
  - Activity: `allPosts.where((p) => p.isLiked)`

  Simple, and `isLiked` is already calculated for you.

### Writing: the controller adds "who"
`FeedController` (`Notifier<void>`) reads `currentUserIdProvider` and passes it to the repository:
```dart
toggleLike(postId)          →  repo.toggleLike(me, postId)
addComment(postId, body)    →  repo.addComment(postId, me, body)
createPost(imageUrl, text)  →  repo.createPost(me, imageUrl, text)
```
The UI never sends a user id, so it can't fake one.

### toggleLike
```
look for a row (me, post) in likes
  found     → DELETE it   (unlike)
  not found → INSERT it   (like)
```

### Delete only your own comment
`DELETE ... WHERE id = ? AND author_id = me`. Someone else's comment matches 0 rows. The UI also hides the button, but the **WHERE clause** is the real protection.

---

## 6. File map

| File | New / changed | What it does |
|---|---|---|
| `lib/core/auth/password_hasher.dart` | new | salt + sha256 |
| `lib/core/db/app_database.dart` | rewritten | 4 tables, migration v2, FK pragma, demo seed |
| `lib/screens/home_screen/services/auth_repository.dart` | new | register / login / getUser / watchUser / updateProfile |
| `lib/screens/home_screen/services/session_store.dart` | new | save/read/clear logged-in id |
| `lib/screens/home_screen/services/posts_repository.dart` | new (replaces `local_data_service.dart`) | feed SQL, likes, comments |
| `lib/screens/home_screen/state/auth_controller.dart` | new | `AuthController`, `currentUserIdProvider`, `userProvider` |
| `lib/screens/home_screen/state/feed_controller.dart` | rewritten | stream providers + `FeedController` actions |
| `lib/screens/home_screen/models/*.dart` | changed | int ids, author info, counts |
| `lib/screens/auth/auth_screen.dart` | new | login/register form |
| `lib/main.dart` | changed | `AuthGate` |
| `lib/screens/tabs/profile_tab.dart` | changed | real user, bio, **logout** button |
| `lib/screens/content/comments_sheet.dart` | changed | author avatar/name, delete own |
| `lib/screens/tabs/activity_tab.dart`, `home_tab.dart`, `new_post_tab.dart`, `content/post_widget.dart` | small changes | use the new providers/fields |
| `test/auth_and_posts_test.dart` | new | 12 tests on an in-memory DB |
| `test/edit_profile_dialog_test.dart` | new | regression test for the Save freeze (see §10) |

---

## 7. How to write it yourself: the order

Do it bottom-up and keep each step compiling:

1. **Packages**
   `flutter pub add crypto shared_preferences` · `flutter pub add --dev drift_dev build_runner`
2. **Tables** in `app_database.dart` (§2), bump `schemaVersion`, add the `migration`, then run `build_runner`.
   *Check:* `app_database.g.dart` now has `User`, `Post`, `Like`, `Comment`.
3. **`password_hasher.dart`**: two functions.
4. **`AuthRepository`**: register (validate, check duplicate, hash, insert) and login (find, compare hash).
   *Check:* write the first 3 tests from `test/auth_and_posts_test.dart` and run `flutter test`.
5. **`PostsRepository`**: start with `createPost` + `watchFeed` (the big SQL), then `toggleLike`, then comments.
   *Check:* the "A likes, B sees count 1, isLiked false" test.
6. **`SessionStore`** + **`AuthController`** + `currentUserIdProvider`.
7. **`AuthGate`** in `main.dart` + **`AuthScreen`**. You can now log in.
8. **`FeedController`** + stream providers, then fix each tab one by one (the analyzer will point at every broken line).
9. **Logout** button in ProfileTab.

---

## 8. Self-check (do this on the emulator)

- [ ] Fresh install shows the login screen. Log in as `aibek.travels` / `password` and the feed has 3 posts.
- [ ] Sign up as a new user. A short password and a taken name both show an error.
- [ ] Like a post. The heart goes red and the count goes up. Comment, and your name shows on the comment.
- [ ] Close the app completely and reopen it. You're **still logged in** and the like is **still there**.
- [ ] Log out and log in as `aizada_k`. The **same post** shows the count, but **her heart is empty**. The Activity tab is empty for her.
- [ ] She can't delete your comment (no button), but she can delete her own.
- [ ] Create a post. It appears in the feed and in **her** profile grid only.
- [ ] `flutter test` passes and `flutter analyze` shows no errors.

---

## 9. Questions you should be able to answer (defence)

1. Why is `Likes` its own table instead of an `isLiked` column? *(many-to-many, per user)*
2. What does the composite primary key in `Likes` prevent?
3. What is a foreign key, and what does `onDelete: cascade` do? Why do we need `PRAGMA foreign_keys = ON`?
4. Why store a hash and salt instead of the password? What is the salt for?
5. Why is `likeCount` computed with `COUNT(*)` and not stored?
6. What is `readsFrom` for in `customSelect`, and what breaks without it?
7. Where is "who is logged in" stored, and why not in the database? What happens on app restart?
8. Why don't `login()` and `logout()` call `Navigator`? Who switches the screen?
9. Why does `MainScreen` get `key: ValueKey(user.id)`?
10. What happens to an old v1 database on a phone when the app updates to v2?

---

## 10. Bug we hit: the app froze on "Save" (Edit profile)

**Symptom:** pressing Save in Edit profile froze the app, and Android showed "App isn't responding".

**Cause:** the old code was
```dart
final controller = TextEditingController();
await showDialog(...);      // returns as soon as Navigator.pop() is called
controller.dispose();       // ...but the dialog is STILL fading out
```
During the ~150 ms close animation, the dialog's `TextField` still uses the controller, so Flutter throws *"A TextEditingController was used after being disposed"*. In debug mode VS Code **pauses** on that exception. Dart now runs on Android's main thread, so a paused Dart means a frozen app, and Android shows the ANR dialog.

**Fix:** the dialog is its own `StatefulWidget` (`_EditProfileDialog`) that creates the controllers and disposes them in `dispose()`. Flutter calls that only after the route is completely gone.

**Rule:** whoever *creates* a controller disposes it, in `State.dispose()`. Never dispose right after `await showDialog`.

**Debug tip:** if the app freezes while running from VS Code, look at the **Debug** panel. It's probably paused on an exception, and it shows which line threw.
