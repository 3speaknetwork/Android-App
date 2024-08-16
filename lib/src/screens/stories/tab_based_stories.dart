/*
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:acela/src/widgets/story_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'package:wakelock/wakelock.dart';

class TabBasedStoriesScreen extends StatefulWidget {
  const TabBasedStoriesScreen({
    Key? key,
    required this.appData,
  });

  final HiveUserData appData;

  @override
  State<TabBasedStoriesScreen> createState() => _TabBasedStoriesScreenState();
}

class _TabBasedStoriesScreenState extends State<TabBasedStoriesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<VideoDetails>> loadCtt;
  late Future<List<VideoDetails>> loadHome;
  late Future<List<VideoDetails>> loadTrending;
  late Future<List<VideoDetails>> loadNew;
  late Future<List<VideoDetails>> loadFirstUploads;
  Future<List<VideoDetails>>? loadMyFeedVideos;
  CarouselSliderController controller = CarouselSliderController();

  var isMenuOpen = false;

  static List<Tab> myTabs = <Tab>[
    Tab(
      icon: Image.asset(
        'assets/ctt-logo.png',
        width: 20,
        height: 20,
      ),
    ),
    Tab(icon: Icon(Icons.person)),
    Tab(icon: Icon(Icons.home)),
    Tab(icon: Icon(Icons.local_fire_department)),
    Tab(icon: Icon(Icons.play_arrow)),
    Tab(icon: Icon(Icons.looks_one)),
  ];

  var urls = [
    '${Communicator.tsServer}/mobile/api/feed/user/@spknetwork.chat',
    '${Communicator.tsServer}/mobile/api/feed/home?shorts=true',
    '${Communicator.tsServer}/mobile/api/feed/trending?shorts=true',
    '${Communicator.tsServer}/mobile/api/feed/new?shorts=true',
    '${Communicator.tsServer}/mobile/api/feed/first?shorts=true',
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
    loadCtt = _loadFeed(urls[0]);
    loadHome = _loadFeed(urls[1]);
    loadTrending = _loadFeed(urls[2]);
    loadNew = _loadFeed(urls[3]);
    loadFirstUploads = _loadFeed(urls[4]);
    if (widget.appData.username != null) {
      loadMyFeedVideos = Communicator().loadMyFeedVideos(widget.appData, true);
    }
    Wakelock.enable();
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
    Wakelock.disable();
  }

  void reloadWithIndex(int index) {
    setState(() {
      if (index == 0) {
        loadCtt = _loadFeed(urls[0]);
      } else if (index == 2) {
        loadHome = _loadFeed(urls[1]);
      } else if (index == 3) {
        loadTrending = _loadFeed(urls[2]);
      } else if (index == 4) {
        loadNew = _loadFeed(urls[3]);
      } else if (index == 5) {
        loadFirstUploads = _loadFeed(urls[4]);
      }
    });
  }

  Widget futureBuilderForTrending(int index) {
    return FutureBuilder(
      future: (index == 0)
          ? loadCtt
          : (index == 2)
              ? loadHome
              : (index == 3)
                  ? loadTrending
                  : (index == 4)
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
          return carousel(list);
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
                          Communicator().loadMyFeedVideos(widget.appData, true);
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
                      Communicator().loadMyFeedVideos(widget.appData, true);
                });
              }
            });
          }
          return carousel(list);
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
        return '@spknetwork.chat';
      case 1:
        return '@${widget.appData.username ?? 'User'}\'s feed - 3Shorts';
      case 2:
        return 'Home feed - 3Shorts';
      case 3:
        return 'Trending feed - 3Shorts';
      case 4:
        return 'New feed - 3Shorts';
      case 5:
        return 'First uploads - 3Shorts';
      default:
        return 'User\'s feed - 3Shorts';
    }
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

  Widget appBarHeader() {
    return ListTile(
      leading: Image.asset(
        'assets/branding/three_shorts_icon.png',
        height: 40,
        width: 40,
      ),
      title: Text('3Shorts'),
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
          'To see 3Shorts\nfrom whom you follow,\nplease login.',
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

  Widget _fullPost(VideoDetails item) {
    return StoryPlayer(
      playUrl: item.videoV2M3U8(widget.appData),
      hlsUrl: item.rootVideoV2M3U8(),
      thumbUrl: item.getThumbnail(),
      data: widget.appData,
      owner: item.owner,
      permlink: item.permlink,
      didFinish: () {
        setState(() {
          controller.nextPage();
        });
      },
    );
  }

  Widget carousel(List<VideoDetails> items) {
    return Container(
      child: CarouselSlider(
        CarouselSliderController: controller,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height,
          enableInfiniteScroll: true,
          viewportFraction: 1,
          scrollDirection: Axis.vertical,
        ),
        items: items.map((item) {
          return Builder(
            builder: (BuildContext context) {
              return _fullPost(item);
            },
          );
        }).toList(),
      ),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
          isScrollable: true,
        ),
        actions: widget.appData.username == null
            ? [
                IconButton(onPressed: () {
                  var screen = HiveAuthLoginScreen(appData: widget.appData);
                  var route = MaterialPageRoute(builder: (c) => screen);
                  Navigator.of(context).push(route);
                }, icon: Icon(Icons.person)),
              ]
            : [],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            futureBuilderForTrending(0),
            widget.appData.username != null
                ? futureBuilderForMyFeed()
                : pleaseLogIn(),
            futureBuilderForTrending(2),
            futureBuilderForTrending(3),
            futureBuilderForTrending(4),
            futureBuilderForTrending(5),
          ],
        ),
      ),
    );
  }
}
*/