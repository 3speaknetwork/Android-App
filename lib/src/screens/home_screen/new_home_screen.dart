import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/home_screen_feed_models/home_feed.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/screens/about/about_home_screen.dart';
import 'package:acela/src/screens/communities_screen/communities_screen.dart';
import 'package:acela/src/screens/leaderboard_screen/leaderboard_screen.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/my_account/my_account_screen.dart';
import 'package:acela/src/screens/search/search_screen.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/new_feed_list_item.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;

class GQLFeedScreen extends StatefulWidget {
  const GQLFeedScreen({
    Key? key,
    required this.appData,
  });

  final HiveUserData appData;

  @override
  State<GQLFeedScreen> createState() => _GQLFeedScreenState();
}

class _GQLFeedScreenState extends State<GQLFeedScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<VideoDetails>> loadHome;
  late Future<List<VideoDetails>> loadTrending;
  late Future<List<VideoDetails>> loadNew;
  late Future<List<VideoDetails>> loadFirstUploads;
  Future<List<VideoDetails>>? loadMyFeedVideos;

  var urls = [
    '${Communicator.tsServer}/mobile/api/feed/home',
    '${Communicator.tsServer}/mobile/api/feed/trending',
    '${Communicator.tsServer}/mobile/api/feed/new',
    '${Communicator.tsServer}/mobile/api/feed/first',
  ];

  static const List<Tab> myTabs = <Tab>[
    Tab(icon: Icon(Icons.person)),
    Tab(icon: Icon(Icons.home)),
    Tab(icon: Icon(Icons.local_fire_department)),
    Tab(icon: Icon(Icons.play_arrow)),
    Tab(icon: Icon(Icons.emoji_emotions)),
    Tab(icon: Icon(Icons.handshake)),
    Tab(icon: Icon(Icons.leaderboard)),
  ];

  late TabController _tabController;
  var currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: myTabs.length);
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
    loadHome = _loadFeed(urls[0]);
    loadTrending = _loadFeed(urls[1]);
    loadNew = _loadFeed(urls[2]);
    loadFirstUploads = _loadFeed(urls[3]);
    if (widget.appData.username != null) {
      loadMyFeedVideos = Communicator().loadMyFeedVideos(widget.appData);
    }
  }

  Future<List<VideoDetails>> _loadFeed(String url) async {
    var response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      return videoItemsFromString(response.body);
    } else {
      throw 'Status code ${response.statusCode}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void reloadWithIndex(int index) {
    setState(() {
      if (index == 0) {
        loadHome = _loadFeed(urls[0]);
      } else if (index == 1) {
        loadTrending = _loadFeed(urls[1]);
      } else if (index == 2) {
        loadNew = _loadFeed(urls[2]);
      } else if (index == 3) {
        loadFirstUploads = _loadFeed(urls[3]);
      }
    });
  }

  Widget futureBuilderForTrending(int index) {
    return FutureBuilder(
      future: (index == 0)
          ? loadHome
          : (index == 1)
              ? loadTrending
              : (index == 2)
                  ? loadNew
                  : loadFirstUploads,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: RetryScreen(
              error: snapshot.error?.toString() ?? 'Something went wrong',
              onRetry: () {
                reloadWithIndex(index);
              },
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          var list = snapshot.data as List<VideoDetails>;
          if (list.isEmpty) {
            return noDataFound(false, () {
              reloadWithIndex(index);
            });
          }
          return RefreshIndicator(
            onRefresh: () async {
              reloadWithIndex(index);
            },
            child: ListView.separated(
              itemBuilder: (c, i) {
                return NewFeedListItem(
                  rpc: widget.appData.rpc,
                  thumbUrl: list[i].getThumbnail(),
                  author: list[i].owner,
                  title: list[i].title,
                  createdAt:
                  DateTime.tryParse(list[i].created) ?? DateTime.now(),
                  duration: list[i].duration,
                  views: list[i].views,
                  permlink: list[i].permlink,
                  onTap: () {},
                  onUserTap: () {},
                );
              },
              separatorBuilder: (c, i) =>
                  const Divider(color: Colors.transparent),
              itemCount: list.length,
            ),
          );
        } else {
          return LoadingScreen(
            title: 'Loading Data',
            subtitle: 'Please wait...',
          );
        }
      },
    );
  }

  Widget futureBuilderForMyFeed() {
    return FutureBuilder(
      future: loadMyFeedVideos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: RetryScreen(
              error: snapshot.error?.toString() ?? 'Something went wrong',
              onRetry: () {
                setState(() {
                  if (widget.appData.username != null) {
                    setState(() {
                      loadMyFeedVideos =
                          Communicator().loadMyFeedVideos(widget.appData);
                    });
                  }
                });
              },
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          var list = snapshot.data as List<VideoDetails>;
          if (list.isEmpty) {
            return noDataFound(true, () {
              if (widget.appData.username != null) {
                setState(() {
                  loadMyFeedVideos =
                      Communicator().loadMyFeedVideos(widget.appData);
                });
              }
            });
          }
          return RefreshIndicator(
            onRefresh: () async {
              if (widget.appData.username != null) {
                setState(() {
                  loadMyFeedVideos =
                      Communicator().loadMyFeedVideos(widget.appData);
                });
              }
            },
            child: ListView.separated(
              itemBuilder: (c, i) {
                return NewFeedListItem(
                  rpc: widget.appData.rpc,
                  thumbUrl: list[i].getThumbnail(),
                  author: list[i].owner,
                  title: list[i].title,
                  createdAt:
                      DateTime.tryParse(list[i].created) ?? DateTime.now(),
                  duration: list[i].duration,
                  views: list[i].views,
                  permlink: list[i].permlink,
                  onTap: () {},
                  onUserTap: () {},
                );
              },
              separatorBuilder: (c, i) =>
                  const Divider(color: Colors.transparent),
              itemCount: list.length,
            ),
          );
        } else {
          return LoadingScreen(
            title: 'Loading Data',
            subtitle: 'Please wait...',
          );
        }
      },
    );
  }

  String getSubtitle() {
    switch (currentIndex) {
      case 0:
        return '${widget.appData.username ?? 'User'}\'s feed';
      case 1:
        return 'Home feed';
      case 2:
        return 'Trending feed';
      case 3:
        return 'New feed';
      case 4:
        return 'First uploads';
      case 5:
        return 'Communities';
      case 6:
        return 'Leaderboard';
      default:
        return 'User\'s feed';
    }
  }

  List<Widget> actions() {
    return [
      IconButton(
        onPressed: () {
          var route = MaterialPageRoute(
            builder: (context) => const SearchScreen(),
          );
          Navigator.of(context).push(route);
        },
        icon: const Icon(Icons.search),
      ),
      if (widget.appData.username != null)
        IconButton(
          onPressed: () {
            // uploadClicked(appData);
          },
          icon: const Icon(Icons.upload),
        ),
      if (widget.appData.username != null)
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => MyAccountScreen(data: widget.appData),
              ),
            );
          },
          icon: CustomCircleAvatar(
            height: 36,
            width: 36,
            url:
                'https://images.hive.blog/u/${widget.appData.username ?? ''}/avatar',
          ),
        )
    ];
  }

  Widget appBarHeader() {
    return ListTile(
      leading: InkWell(
        child: CircleAvatar(
          child: ClipOval(
              child: Image.asset('assets/branding/three_speak_icon.png',
                  height: 40, width: 40)),
          radius: 20,
        ),
        onTap: () {
          var screen = const AboutHomeScreen();
          var route = MaterialPageRoute(builder: (_) => screen);
          Navigator.of(context).push(route);
        },
      ),
      title: Text('3Speak.tv'),
      subtitle: Text(getSubtitle()),
    );
  }

  Widget pleaseLogIn() {
    return Column(
      children: [
        Spacer(),
        Icon(Icons.rss_feed, size: 60),
        SizedBox(height: 20),
        Text(
          'To see videos\nfrom whom you follow,\nplease login.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            var screen = HiveAuthLoginScreen(appData: widget.appData);
            var route = MaterialPageRoute(builder: (c) => screen);
            Navigator.of(context).push(route);
          },
          child: Text('Login'),
        ),
        Spacer(),
      ],
    );
  }

  Widget noDataFound(bool isMyFeed, Function retry) {
    return Column(
      children: [
        Spacer(),
        Icon(Icons.autorenew, size: 60),
        SizedBox(height: 20),
        Text(
          'We did not find anything to show.\nTap on retry to load again.${isMyFeed ? '\nOR Follow more users' : ''}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            retry();
          },
          child: Text('Retry'),
        ),
        Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appData.username != null && loadMyFeedVideos == null) {
      loadMyFeedVideos = Communicator().loadMyFeedVideos(widget.appData);
    }
    return Scaffold(
      appBar: AppBar(
        title: appBarHeader(),
        actions: actions(),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          widget.appData.username != null
              ? futureBuilderForMyFeed()
              : pleaseLogIn(),
          futureBuilderForTrending(0),
          futureBuilderForTrending(1),
          futureBuilderForTrending(2),
          futureBuilderForTrending(3),
          CommunitiesScreen(
            didSelectCommunity: null,
            withoutScaffold: true,
          ),
          LeaderboardScreen(withoutScaffold: true),
        ],
      ),
    );
  }
}
