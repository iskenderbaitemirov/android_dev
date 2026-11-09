import "package:android_dev/screens/content/post_widget.dart";
import "package:android_dev/screens/content/stories_list.dart";
import "package:android_dev/screens/home_screen/data/mock_data.dart";
import "package:android_dev/screens/home_screen/services/post_services.dart";
import "package:flutter/material.dart";

class HomeTab extends StatefulWidget {
  const new({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PostServices postServices = PostServices()
    ..batchAddPosts(createMockPosts())
    ..batchAddStories(createMockStories());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('something like Instagram'),
      ),
      body: Column(
        children: [
          StoriesList(stories: postServices.stories),
          // Expanded gives the vertical list "all the remaining height".
          Expanded(
            child: ListView.builder(
              itemCount: postServices.posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: PostWidget(post: postServices.posts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
