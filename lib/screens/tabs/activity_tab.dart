import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityTab extends ConsumerWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load activity: $error')),
        data: (allPosts) {
          final items = allPosts.where((post) => post.isLiked).toList();
          return items.isEmpty
              ? const Center(child: Text('Posts you like will appear here.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Image.network(
                      items[index].imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                    title: Text('You liked ${items[index].authorName}\'s post'),
                    subtitle: Text(items[index].caption, maxLines: 1),
                  ),
                );
        },
      ),
    );
  }
}
