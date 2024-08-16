import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/about/about_home_screen.dart';
import 'package:acela/src/screens/communities_screen/communities_screen.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/bottom_nav_bar.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/tab_title_toast.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_list.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/trending_tags/trending_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

class GQLFeedScreen extends StatefulWidget {
  const GQLFeedScreen({
    Key? key,
    required this.appData,
    required this.username,
  });

  final HiveUserData appData;
  final String? username;

  @override
  State<GQLFeedScreen> createState() => _GQLFeedScreenState();
}

class _GQLFeedScreenState extends State<GQLFeedScreen>
    with TickerProviderStateMixin {
  var isMenuOpen = false;

  List<Tab> myTabs() {
    return widget.username != null
        ? <Tab>[
            Tab(icon: Icon(Icons.person)),
            // Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
            Tab(icon: Icon(Icons.handshake)),
            Tab(icon: Icon(Icons.tag)),
          ]
        : <Tab>[
            // Tab(icon: Icon(Icons.home)),
            Tab(icon: Icon(Icons.local_fire_department)),
            Tab(icon: Icon(Icons.play_arrow)),
            Tab(icon: Icon(Icons.looks_one)),
            Tab(icon: Icon(Icons.handshake)),
            Tab(icon: Icon(Icons.tag)),
          ];
  }

  late TabController _tabController;
  var currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(vsync: this, length: widget.username != null ? 6 : 5);
    _tabController.addListener(tabBarListener);
  }

  @override
  void didUpdateWidget(covariant GQLFeedScreen oldWidget) {
    if (widget.username != oldWidget.username) {
      _tabController.removeListener(tabBarListener);
      _tabController.dispose();
      _tabController =
          TabController(vsync: this, length: widget.username != null ? 6 : 5);
      _tabController.addListener(tabBarListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  void tabBarListener() {
    setState(() {
      currentIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(tabBarListener);
    _tabController.dispose();
    super.dispose();
  }

  String getSubtitle() {
    if (widget.username != null) {
      switch (currentIndex) {
        case 0:
          return '@${widget.username ?? 'User'}\'s feed';
        case 1:
          return 'Trending feed';
        case 2:
          return 'New feed';
        case 3:
          return 'First uploads';
        case 4:
          return 'Communities';
        case 5:
          return 'Trending Tags';
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
          return 'Communities';
        case 4:
          return 'Trending Tags';
        default:
          return 'User\'s feed';
      }
    }
  }

  Widget appBarHeader() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: InkWell(
        child: ClipOval(
            child: Image.asset('assets/branding/three_speak_icon.png',
                height: 33, width: 33)),
        onTap: () {
          var screen = const AboutHomeScreen();
          var route = MaterialPageRoute(builder: (_) => screen);
          Navigator.of(context).push(route);
        },
      ),
      title: Text('3Speak.tv'),
      subtitle: Text('Powered by Hive'),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    return UpgradeAlert(
      showIgnore: true,
      showReleaseNotes: true,
      child: Scaffold(
        bottomNavigationBar: BottomNavBar(
          appData: widget.appData,
          username: widget.username,
        ),
        appBar: AppBar(
          title: appBarHeader(),
          bottom: TabBar(
            controller: _tabController,
            onTap: (value) {
              setState(() {
                currentIndex = value;
              });
            },
            tabs: myTabs(),
          ),
          actions: [
            if (widget.username == null)
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: SizedBox(
                  height: 25,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        padding:
                            EdgeInsets.symmetric(horizontal: 2, vertical: 0)),
                    onPressed: () {
                      var screen = HiveAuthLoginScreen(appData: widget.appData);
                      var route = MaterialPageRoute(builder: (c) => screen);
                      Navigator.of(context).push(route);
                    },
                    child: Text('Log In'),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              TabBarView(
                  key: ValueKey('${widget.username}'),
                  controller: _tabController,
                  children: widget.username != null
                      ? [
                          HomeScreenFeedList(
                            key: ValueKey("${widget.username} 0"),
                            showVideo: currentIndex == 0,
                            feedType: HomeScreenFeedType.userFeed,
                            appData: appData,
                            onEmptyDataCallback: () {
                              _tabController.animateTo(1);
                            },
                          ),
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 1"),
                              showVideo: currentIndex == 1,
                              feedType: HomeScreenFeedType.trendingFeed,
                              appData: appData),
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 2"),
                              showVideo: currentIndex == 2,
                              feedType: HomeScreenFeedType.newUploads,
                              appData: appData),
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 3"),
                              showVideo: currentIndex == 3,
                              feedType: HomeScreenFeedType.firstUploads,
                              appData: appData),
                          CommunitiesScreen(
                            key: ValueKey("${widget.username} 4"),
                            didSelectCommunity: null,
                            withoutScaffold: true,
                          ),
                          TrendingTagsWidget(
                            key: ValueKey("${widget.username} 5"),
                          ),
                        ]
                      : [
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 0"),
                              showVideo: currentIndex == 0,
                              feedType: HomeScreenFeedType.trendingFeed,
                              appData: appData),
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 1"),
                              showVideo: currentIndex == 1,
                              feedType: HomeScreenFeedType.newUploads,
                              appData: appData),
                          HomeScreenFeedList(
                              key: ValueKey("${widget.username} 2"),
                              showVideo: currentIndex == 2,
                              feedType: HomeScreenFeedType.firstUploads,
                              appData: appData),
                          CommunitiesScreen(
                            key: ValueKey("${widget.username} 3"),
                            didSelectCommunity: null,
                            withoutScaffold: true,
                          ),
                          TrendingTagsWidget(
                            key: ValueKey("${widget.username} 4"),
                          ),
                        ]),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: HomeScreenTabTitleToast(
                    subtitle: getSubtitle(),
                    tabIndex: currentIndex,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
