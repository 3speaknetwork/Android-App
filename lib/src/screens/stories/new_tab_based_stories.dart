import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/stories/story_feed_list.dart';
import 'package:flutter/material.dart';

class GQLStoriesScreen extends StatefulWidget {
  const GQLStoriesScreen({
    Key? key,
    required this.appData,
  });

  final HiveUserData appData;

  @override
  State<GQLStoriesScreen> createState() => _GQLStoriesScreenState();
}

class _GQLStoriesScreenState extends State<GQLStoriesScreen>
    with SingleTickerProviderStateMixin {
  var isMenuOpen = false;

  List<Tab> myTabs() {
    return widget.appData.username != null
        ? <Tab>[
            Tab(
              icon: Image.asset(
                'assets/ctt-logo.png',
                width: 30,
                height: 30,
              ),
            ),
            Tab(icon: Icon(Icons.person)),
            // Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
          ]
        : <Tab>[
            Tab(
              icon: Image.asset(
                'assets/ctt-logo.png',
                width: 30,
                height: 30,
              ),
            ),
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
          ];
  }

  late TabController _tabController;
  var currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        vsync: this, length: widget.appData.username != null ? 5 : 4);
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String getSubtitle() {
    if (widget.appData.username != null) {
      switch (currentIndex) {
        case 0:
          return 'CTT Chat';
        case 1:
          return '@${widget.appData.username ?? 'User'}\'s feed';
        case 2:
          return 'Trending feed';
        case 3:
          return 'New feed';
        case 4:
          return 'First uploads';
        default:
          return 'User\'s feed';
      }
    } else {
      switch (currentIndex) {
        case 0:
          return 'CTT Chat';
        case 1:
          return 'Trending feed';
        case 2:
          return 'New feed';
        case 3:
          return 'First uploads';
        default:
          return 'User\'s feed';
      }
    }
  }

  Widget appBarHeader() {
    return ListTile(
      leading: Image.asset(
        'assets/branding/three_shorts_icon.png',
        height: 40,
        width: 40,
      ),
      title: Text('3Speak.tv'),
      subtitle: Text(getSubtitle()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBarHeader(),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs(),
          isScrollable: true,
        ),
        actions: [],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: widget.appData.username != null
              ? [
                  StoryFeedList(
                      appData: widget.appData, feedType: StoryFeedType.cttFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.userFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.trendingFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.newUploads),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.firstUploads),
                ]
              : [
                  StoryFeedList(
                      appData: widget.appData, feedType: StoryFeedType.cttFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.trendingFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.newUploads),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.firstUploads),
                ],
        ),
      ),
    );
  }
}