import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/screens/home_screen/services/auth_repository.dart';
import 'package:android_dev/screens/home_screen/state/auth_controller.dart';
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink(); // logging out

    final user = ref.watch(userProvider(userId)).value;
    final posts = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(user?.username ?? 'Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: user == null
                ? null
                : () => _showEditProfile(context, ref, user),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load profile: $error')),
        data: (allPosts) {
          final ownPosts = allPosts.where((p) => p.authorId == userId).toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: user?.avatarUrl == null
                            ? null
                            : NetworkImage(user!.avatarUrl!),
                        child: user?.avatarUrl == null
                            ? Text(
                                (user?.username ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (user?.bio != null) Text(user!.bio!),
                            const SizedBox(height: 6),
                            Text('${ownPosts.length} posts'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Posts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (ownPosts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No posts yet.')),
                  ),
                ),
              SliverGrid.builder(
                itemCount: ownPosts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) =>
                    Image.network(ownPosts[index].imageUrl, fit: BoxFit.cover),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    // AuthGate sees `null` and shows the login screen. No navigation needed.
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) => showDialog<void>(
    context: context,
    builder: (_) => _EditProfileDialog(user: user),
  );
}

/// The dialog OWNS its text controllers, so they're disposed in [dispose].
///
/// Bug this avoids: creating the controllers in a function and disposing them
/// right after `await showDialog(...)`. `showDialog` returns as soon as
/// `Navigator.pop` is called, but the dialog is still on screen during its
/// fade-out animation and its TextFields still use the controllers. Result:
/// "A TextEditingController was used after being disposed", and with the
/// debugger attached the app freezes on that exception.
/// `State.dispose()` only runs after the route is completely gone.
class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.user});

  final User user;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final _avatar = TextEditingController(text: widget.user.avatarUrl ?? '');
  late final _bio = TextEditingController(text: widget.user.bio ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _avatar.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final avatar = _avatar.text.trim();
    final bio = _bio.text.trim();
    await ref
        .read(authRepositoryProvider)
        .updateProfile(
          widget.user.id,
          avatarUrl: avatar.isEmpty ? null : avatar,
          bio: bio.isEmpty ? null : bio,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit profile'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _avatar,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'Profile picture URL'),
        ),
        TextField(
          controller: _bio,
          decoration: const InputDecoration(labelText: 'Bio'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}
