import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/favourites/favourite_shorts_body.dart';
import 'package:acela/src/screens/favourites/favourite_tags_body.dart';
import 'package:acela/src/screens/favourites/favourite_users_body.dart';
import 'package:acela/src/screens/favourites/favourite_video_body.dart';
import 'package:acela/src/screens/podcast/view/liked_podcasts.dart';
import 'package:acela/src/screens/podcast/view/local_podcast_episode.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class UserFavourites extends StatefulWidget {
  const UserFavourites({Key? key}) : super(key: key);

  @override
  State<UserFavourites> createState() => _UserFavouritesState();
}

class _UserFavouritesState extends State<UserFavourites>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          title: Text('Bookmarks'),
          subtitle: Text(appBarSubtitle()),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.play_arrow)),
            Tab(icon: const Icon(Icons.video_library_rounded)),
            Tab(icon: const Icon(Icons.tag)),
            Tab(icon: const Icon(Icons.person)),
            Tab(icon: const Icon(Icons.podcasts)),
            Tab(icon: const Icon(Icons.queue_music_rounded)),
            Tab(icon: const Icon(FontAwesomeIcons.download)),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        FavouriteVideoBody(appData: appData),
        FavouriteShortsBody(
          appData: appData,
        ),
        FavouriteTagsBody(),
        FavouriteUsersBody(),
        LikedPodcasts(
          appData: appData,
          showAppBar: false,
        ),
        LocalEpisodeListView(isOffline: false),
        LocalEpisodeListView(isOffline: true),
      ]),
    );
  }

  String appBarSubtitle() {
    switch (currentIndex) {
      case 0:
        return "Videos";
      case 1:
        return "Shorts";
      case 2:
        return "Tags";
      case 3:
        return "Users";
      case 4:
        return "Podcasts";
      case 5:
        return "Podcast Episode";
      case 6:
        return "Offline Podcast Episode";
      default:
        return "";
    }
  }
}
