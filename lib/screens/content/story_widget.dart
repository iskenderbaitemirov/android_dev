import 'package:android_dev/screens/home_screen/models/story_model.dart';
import 'package:android_dev/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class StoryWidget extends StatelessWidget {
  final StoryModel story;
  const StoryWidget({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.isSeen
                  ? null
                  : const LinearGradient(
                      colors: [Colors.purple, Colors.orange],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
              color: story.isSeen ? Colors.grey : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: UserAvatar(url: story.avatarUrl, radius: 27),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              story.userName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
