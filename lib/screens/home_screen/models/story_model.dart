class StoryModel {
  final String userName;
  final String avatarUrl;
  final bool isSeen;

  const StoryModel({
    required this.userName,
    required this.avatarUrl,
    this.isSeen = false,
  });
}
