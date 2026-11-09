import 'package:android_dev/screens/home_screen/models/comment_model.dart';
import 'package:android_dev/screens/home_screen/models/post_model.dart';
import 'package:android_dev/screens/home_screen/models/story_model.dart';

// Avatars: real faces from randomuser.me (men/<n>.jpg or women/<n>.jpg, n = 0–99).
String _man(int n) => 'https://randomuser.me/api/portraits/men/$n.jpg';
String _woman(int n) => 'https://randomuser.me/api/portraits/women/$n.jpg';

// Post photos: Wikimedia Commons (free licenses), resized to 800px wide.

/// A function (not a `final List`) so every call builds NEW PostModel objects.
/// Otherwise every screen would share, and mutate, the same instances.
List<PostModel> createMockPosts() => [
      PostModel(
        userName: 'aibek.travels',
        avatarUrl: _man(11),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/58/Lake_Issyk-Kul%2C_Kyrgyzstan.jpg/960px-Lake_Issyk-Kul%2C_Kyrgyzstan.jpg',
        description: 'Sunrise over Issyk-Kul. Worth waking up at 5 am 🌅',
        likeCount: 124,
        comments: [
          CommentModel(userName: 'aizada_k', avatarUrl: _woman(5), text: 'Wow, beautiful!', likeCount: 12),
          CommentModel(userName: 'timur.dev', avatarUrl: _man(12), text: 'Which beach is this?'),
        ],
      ),
      PostModel(
        userName: 'aizada_k',
        avatarUrl: _woman(5),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1a/A_cup_of_coffee_and_a_donut_next_to_a_laptop._Woman_using_her_phone_in_a_blurry.jpg/960px-A_cup_of_coffee_and_a_donut_next_to_a_laptop._Woman_using_her_phone_in_a_blurry.jpg',
        description: 'Coffee + Flutter homework = perfect Sunday ☕',
        likeCount: 58,
        comments: [
          CommentModel(userName: 'nurlan_99', avatarUrl: _man(13), text: 'Same here 😅'),
        ],
      ),
      PostModel(
        userName: 'timur.dev',
        avatarUrl: _man(12),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c0/Laptop_on_desk_book_stacks_%28Unsplash%29.jpg/960px-Laptop_on_desk_book_stacks_%28Unsplash%29.jpg',
        description: 'Finally fixed that null-safety error. Read the error message, people!',
        likeCount: 33,
      ),
      PostModel(
        userName: 'nurlan_99',
        avatarUrl: _man(13),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/69/%D0%90%D0%BB%D0%B0-%D0%90%D1%80%D1%87%D0%B0_%D1%81%D0%B2%D0%B5%D1%80%D1%85%D1%83_%281%29.jpg/960px-%D0%90%D0%BB%D0%B0-%D0%90%D1%80%D1%87%D0%B0_%D1%81%D0%B2%D0%B5%D1%80%D1%85%D1%83_%281%29.jpg',
        description: 'Ala-Archa trail, 14 km. My legs are gone.',
        likeCount: 210,
        comments: [
          CommentModel(userName: 'aibek.travels', avatarUrl: _man(11), text: 'Respect 💪'),
          CommentModel(userName: 'dana.art', avatarUrl: _woman(9), text: 'Take me next time!'),
          CommentModel(userName: 'erlan_photo', avatarUrl: _man(14), text: 'Great light in this shot'),
        ],
      ),
      PostModel(
        userName: 'dana.art',
        avatarUrl: _woman(9),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/64/Fleurs_-_French_Impressionist_Watercolor%2C_Still_Life_of_Flowers_by_Henri_Duhem_c1920.jpg/960px-Fleurs_-_French_Impressionist_Watercolor%2C_Still_Life_of_Flowers_by_Henri_Duhem_c1920.jpg',
        description: 'New watercolor piece. Thoughts?',
        likeCount: 87,
        comments: [
          CommentModel(userName: 'aizada_k', avatarUrl: _woman(5), text: 'Love the colors'),
        ],
      ),
      PostModel(
        userName: 'erlan_photo',
        avatarUrl: _man(14),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/I_love_Bishkek.jpg/960px-I_love_Bishkek.jpg',
        description: 'Evening walk in Bishkek ❤️',
        likeCount: 301,
      ),
      PostModel(
        userName: 'madina.cooks',
        avatarUrl: _woman(20),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8e/Polu.jpg/960px-Polu.jpg',
        description: 'Plov for 12 people. Recipe in comments 👇',
        likeCount: 145,
        comments: [
          CommentModel(userName: 'madina.cooks', avatarUrl: _woman(20), text: 'Rice, carrots, lamb, cumin, patience.', likeCount: 8),
          CommentModel(userName: 'nurlan_99', avatarUrl: _man(13), text: 'Patience is the secret ingredient'),
        ],
      ),
      PostModel(
        userName: 'bekzat.fit',
        avatarUrl: _man(15),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/79/Colorful_pile_of_dumbbells_at_the_gym_2.jpg/960px-Colorful_pile_of_dumbbells_at_the_gym_2.jpg',
        description: 'Day 30 of training. Consistency > motivation.',
        likeCount: 76,
      ),
      PostModel(
        userName: 'alina.reads',
        avatarUrl: _woman(16),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2b/Stack_of_multicolored_books_on_a_table.jpg/960px-Stack_of_multicolored_books_on_a_table.jpg',
        description: 'November reading list 📚',
        likeCount: 49,
        comments: [
          CommentModel(userName: 'dana.art', avatarUrl: _woman(9), text: 'What is the second book?'),
        ],
      ),
      PostModel(
        userName: 'sultan.cars',
        avatarUrl: _man(17),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/18/Car_Wash%2C_autolavado.jpg/960px-Car_Wash%2C_autolavado.jpg',
        description: 'Car wash done. It will rain tomorrow, guaranteed.',
        likeCount: 92,
      ),
      PostModel(
        userName: 'aigerim.music',
        avatarUrl: _woman(23),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e0/Man_playing_an_acoustic_brazilian_guitar_%28Viol%C3%A3o%29_on_Marco_Zero_Square%2C_Refice%2C_Pernambuco%2C_Brazil.jpg/960px-Man_playing_an_acoustic_brazilian_guitar_%28Viol%C3%A3o%29_on_Marco_Zero_Square%2C_Refice%2C_Pernambuco%2C_Brazil.jpg',
        description: 'Learning komuz and guitar at the same time. Brain = 🔥',
        likeCount: 118,
        comments: [
          CommentModel(userName: 'erlan_photo', avatarUrl: _man(14), text: 'Upload a video!'),
        ],
      ),
      PostModel(
        userName: 'kanat.code',
        avatarUrl: _man(18),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3d/CSS_code_on_a_screen_%28Unsplash%29.jpg/960px-CSS_code_on_a_screen_%28Unsplash%29.jpg',
        description: 'ListView.builder only builds what is on screen. Mind blown.',
        likeCount: 64,
        comments: [
          CommentModel(userName: 'timur.dev', avatarUrl: _man(12), text: 'Lazy loading ftw'),
        ],
      ),
      PostModel(
        userName: 'zarina.style',
        avatarUrl: _woman(24),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/17/Fall_Fashion_%28Unsplash%29.jpg/960px-Fall_Fashion_%28Unsplash%29.jpg',
        description: 'Autumn outfit check 🍂',
        likeCount: 233,
      ),
      PostModel(
        userName: 'azamat.hikes',
        avatarUrl: _man(33),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bf/Son-Kul%2C_Kyrgyzstan_%2844623421951%29.jpg/960px-Son-Kul%2C_Kyrgyzstan_%2844623421951%29.jpg',
        description: 'Son-Kul in October: cold, quiet, perfect.',
        likeCount: 176,
        comments: [
          CommentModel(userName: 'aibek.travels', avatarUrl: _man(11), text: 'Adding to my list!'),
        ],
      ),
      PostModel(
        userName: 'elnura.pets',
        avatarUrl: _woman(25),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/81/Cat_Sleeping_on_Keyboard.jpg/960px-Cat_Sleeping_on_Keyboard.jpg',
        description: 'He sat on my keyboard and pushed to main.',
        likeCount: 412,
        comments: [
          CommentModel(userName: 'kanat.code', avatarUrl: _man(18), text: 'Senior developer cat', likeCount: 41),
          CommentModel(userName: 'alina.reads', avatarUrl: _woman(16), text: '😂😂😂'),
        ],
      ),
      PostModel(
        userName: 'ruslan.ball',
        avatarUrl: _man(51),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cb/Amateur_football_match_between_Wales_and_England_at_Porthmadog_%281496762%29.jpg/960px-Amateur_football_match_between_Wales_and_England_at_Porthmadog_%281496762%29.jpg',
        description: 'Sunday football with the AIT team ⚽',
        likeCount: 55,
      ),
      PostModel(
        userName: 'saule.garden',
        avatarUrl: _woman(26),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/54/Autumn_garden_-_geograph.org.uk_-_6296805.jpg/960px-Autumn_garden_-_geograph.org.uk_-_6296805.jpg',
        description: 'Last flowers of the season.',
        likeCount: 39,
      ),
      PostModel(
        userName: 'daniyar.film',
        avatarUrl: _man(52),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d2/Popcorn_in_cinema_IMG_7715.jpg/960px-Popcorn_in_cinema_IMG_7715.jpg',
        description: 'Movie night. Recommend me something!',
        likeCount: 27,
        comments: [
          CommentModel(userName: 'zarina.style', avatarUrl: _woman(24), text: 'Interstellar, always'),
        ],
      ),
      PostModel(
        userName: 'meerim.bakes',
        avatarUrl: _woman(27),
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/23/Honey_cake_Medovik.jpg',
        description: 'Honey cake attempt #3. This one survived.',
        likeCount: 98,
      ),
      PostModel(
        userName: 'islam.sky',
        avatarUrl: _man(53),
        imageUrl: 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Colorful_sky_with_orange_clouds_reflecting_in_the_water_of_a_paddy_field%2C_at_sunset%2C_Vang_Vieng%2C_Laos.jpg/960px-Colorful_sky_with_orange_clouds_reflecting_in_the_water_of_a_paddy_field%2C_at_sunset%2C_Vang_Vieng%2C_Laos.jpg',
        description: 'No filter. The sky did all the work.',
        likeCount: 150,
        comments: [
          CommentModel(userName: 'erlan_photo', avatarUrl: _man(14), text: 'Golden hour 👌'),
        ],
      ),
    ];

List<StoryModel> createMockStories() => [
      StoryModel(userName: 'Your story', avatarUrl: _man(60)),
      StoryModel(userName: 'aibek.travels', avatarUrl: _man(11)),
      StoryModel(userName: 'aizada_k', avatarUrl: _woman(5)),
      StoryModel(userName: 'timur.dev', avatarUrl: _man(12)),
      StoryModel(userName: 'nurlan_99', avatarUrl: _man(13), isSeen: true),
      StoryModel(userName: 'dana.art', avatarUrl: _woman(9)),
      StoryModel(userName: 'erlan_photo', avatarUrl: _man(14), isSeen: true),
      StoryModel(userName: 'madina.cooks', avatarUrl: _woman(20)),
      StoryModel(userName: 'elnura.pets', avatarUrl: _woman(25)),
      StoryModel(userName: 'kanat.code', avatarUrl: _man(18), isSeen: true),
    ];
