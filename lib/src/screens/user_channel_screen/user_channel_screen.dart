import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_list.dart';
import 'package:acela/src/screens/stories/story_feed_list.dart';
import 'package:acela/src/screens/user_channel_screen/user_channel_following.dart';
import 'package:acela/src/screens/user_channel_screen/user_channel_profile.dart';
import 'package:acela/src/screens/user_channel_screen/user_channel_videos.dart';
import 'package:acela/src/screens/user_channel_screen/user_favourite_provider.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class UserChannelScreen extends StatefulWidget {
  const UserChannelScreen( {Key? key, required this.owner, this.onPop})
      : super(key: key);
  final String owner;
  final VoidCallback? onPop;

  @override
  _UserChannelScreenState createState() => _UserChannelScreenState();
}

class _UserChannelScreenState extends State<UserChannelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var currentIndex = 0;
  var videoKey = GlobalKey<UserChannelVideosState>();
  var userFavouriteProvider = UserFavoriteProvider();

  static List<Tab> tabs = [
    Tab(
      icon: Icon(Icons.video_camera_front_outlined),
    ),
    Tab(
      icon: Image.asset(
        'assets/branding/three_shorts_icon.png',
        width: 30,
        height: 30,
      ),
    ),
    Tab(icon: Icon(Icons.info)),
    Tab(text: 'Followers'),
    Tab(text: 'Following'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
  }

  @override
  void deactivate() {
    if (widget.onPop != null) widget.onPop!();
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  // Widget _sortButton() {
  //   return IconButton(
  //     onPressed: () {
  //       _showBottomSheet();
  //     },
  //     icon: const Icon(Icons.sort),
  //   );
  // }

  void _showBottomSheet() {
    showAdaptiveActionSheet(
      context: context,
      title: const Text('Sort by:'),
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: const Text('Newest'),
          onPressed: (context) {
            videoKey.currentState?.sortByNewest();
          },
        ),
        BottomSheetAction(
          title: const Text('Most Viewed'),
          onPressed: (context) {
            videoKey.currentState?.sortByMostViewed();
          },
        ),
      ],
      cancelAction: CancelAction(title: const Text('Cancel')),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            CustomCircleAvatar(
              height: 36,
              width: 36,
              url: server.userOwnerThumb(widget.owner),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              widget.owner,
              style: TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        actions: [

          IconButton(
            onPressed: () async {
              Share.share("https://3speak.tv/rss/${widget.owner}.xml");
            },
            icon: Icon(Icons.rss_feed),
          ),
          IconButton(
            onPressed: () async {
              Share.share("https://3speak.tv/user/${widget.owner}");
            },
            icon: Icon(Icons.share),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeScreenFeedList(
            appData: appData,
            feedType: HomeScreenFeedType.userChannelFeed,
            owner: widget.owner,
          ),
          StoryFeedList(
            appData: appData,
            feedType: StoryFeedType.userChannelFeed,
            username: widget.owner,
          ),
          UserChannelProfileWidget(owner: widget.owner),
          UserChannelFollowingWidget(owner: widget.owner, isFollowers: true),
          UserChannelFollowingWidget(owner: widget.owner, isFollowers: false),
        ],
      ),
    );
  }
}
