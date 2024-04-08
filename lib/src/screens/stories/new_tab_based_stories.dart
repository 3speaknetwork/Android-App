import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/video_upload_sheet.dart';
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
            // Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
            Tab(icon: Icon(Icons.person)),
            Tab(
              icon: Image.asset(
                'assets/ctt-logo.png',
                width: 30,
                height: 30,
              ),
            ),
          ]
        : <Tab>[
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
            Tab(
              icon: Image.asset(
                'assets/ctt-logo.png',
                width: 30,
                height: 30,
              ),
            ),
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
          return 'Trending feed';
        case 1:
          return 'New feed';
        case 2:
          return 'First uploads';
        case 3:
          return '@${widget.appData.username ?? 'User'}\'s feed';
        case 4:
          return 'CTT Chat';
        default:
          return 'User\'s feed';
      }
    } else {
      switch (currentIndex) {
        case 0:
          return 'Trending feed';
        case 1:
          return 'New feed';
        case 2:
          return 'First uploads';
        case 3:
          return 'CTT Chat';
        default:
          return 'User\'s feed';
      }
    }
  }

  Widget appBarHeader() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Image.asset(
        'assets/branding/three_shorts_icon.png',
        height: 40,
        width: 40,
      ),
      title: Text(
        '3Speak.tv',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        getSubtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: BackButton(),
        ),
        title: appBarHeader(),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs(),
        ),
        actions: [_postVideoButton(widget.appData)],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: widget.appData.username != null
              ? [
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.trendingFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.newUploads),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.firstUploads),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.userFeed),
                  StoryFeedList(
                      appData: widget.appData, feedType: StoryFeedType.cttFeed),
                ]
              : [
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.trendingFeed),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.newUploads),
                  StoryFeedList(
                      appData: widget.appData,
                      feedType: StoryFeedType.firstUploads),
                  StoryFeedList(
                      appData: widget.appData, feedType: StoryFeedType.cttFeed),
                ],
        ),
      ),
    );
  }

  Widget _postVideoButton(HiveUserData data) {
    return Visibility(
      visible: data.username != null,
      child: IconButton(
        color: Theme.of(context).primaryColorLight,
        onPressed: () {
          VideoUploadSheet.show(data, context);
        },
        icon: Icon(Icons.add),
      ),
    );
  }
}
