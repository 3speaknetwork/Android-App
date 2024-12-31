import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_list.dart';
import 'package:acela/src/screens/stories/story_feed_list.dart';
import 'package:acela/src/screens/trending_tags/tag_favourite_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrendingTagVideos extends StatefulWidget {
  const TrendingTagVideos({
    Key? key,
    required this.tag,
  });

  final String tag;

  @override
  State<TrendingTagVideos> createState() => _TrendingTagVideosState();
}

class _TrendingTagVideosState extends State<TrendingTagVideos>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  var currentIndex = 0;
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
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    var provider = TagFavoriteProvider();
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          leading: const Icon(Icons.tag),
          title: Text(widget.tag),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
        actions: [
          
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomeScreenFeedList(
            appData: appData,
            feedType: HomeScreenFeedType.trendingTag,
            owner: widget.tag,
          ),
          StoryFeedList(
            appData: appData,
            feedType: StoryFeedType.trendingTag,
            username: widget.tag,
          ),
        ],
      ),
    );
  }
}
