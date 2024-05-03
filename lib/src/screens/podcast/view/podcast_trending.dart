import 'dart:developer';

import 'package:acela/src/models/podcast/podcast_categories_response.dart';
import 'package:acela/src/models/podcast/trending_podcast_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_player_controller.dart';
import 'package:acela/src/screens/podcast/view/add_rss_podcast.dart';
import 'package:acela/src/screens/podcast/view/liked_podcasts.dart';
import 'package:acela/src/screens/podcast/view/local_podcast_episode.dart';
import 'package:acela/src/screens/podcast/view/podcast_search.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/new_pod_cast_epidose_player.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_categories_body.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_feed_item.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_feeds_body.dart';
import 'package:acela/src/screens/upload/podcast/podcast_upload_screen.dart';
import 'package:acela/src/utils/podcast/podcast_communicator.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';

import '../../../widgets/fab_custom.dart';
import '../../../widgets/fab_overlay.dart';

final miniPlayerNavigatorkey = GlobalKey<NavigatorState>();

class PodCastTrendingScreen extends StatefulWidget {
  const PodCastTrendingScreen({
    Key? key,
    required this.appData,
  });

  final HiveUserData appData;

  @override
  State<PodCastTrendingScreen> createState() => _PodCastTrendingScreenState();
}

class _PodCastTrendingScreenState extends State<PodCastTrendingScreen>
    with SingleTickerProviderStateMixin {
  bool isMenuOpen = false;
  late Future<TrendingPodCastResponse> trendingFeeds;
  late Future<TrendingPodCastResponse> recentFeeds;
  late Future<TrendingPodCastResponse> liveFeeds;
  late Future<List<PodcastCategory>> categories;
  final PodCastCommunicator podCastCommunicator = PodCastCommunicator();
  late TabController _tabController;
  var currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        currentIndex = _tabController.index;
      });
    });
    trendingFeeds = podCastCommunicator.getTrendingPodcasts();
    recentFeeds = podCastCommunicator.getRecentPodcasts();
    categories = podCastCommunicator.getCategories();
    liveFeeds = podCastCommunicator.getLivePodcasts();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  Widget getList(List<PodCastFeedItem> items) {
    return ListView.separated(
      itemBuilder: (c, i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == items.length - 1 ? 65.0 : 0),
          child: PodcastFeedItemWidget(
            appData: widget.appData,
            item: items[i],
          ),
        );
      },
      separatorBuilder: (c, i) => const Divider(height: 0),
      itemCount: items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    var text = currentIndex == 0
        ? 'Trending Podcasts'
        : currentIndex == 1
            ? "RSS Podcasts"
            : currentIndex == 2
                ? 'Explore Podcasts by Categories'
                : currentIndex == 3
                    ? 'Recent Podcasts & Episodes'
                    : 'Live Podcasts';
    return PopScope(
      canPop: true,
      child: MiniplayerWillPopScope(
        onWillPop: () async {
          final NavigatorState navigatorState =
              miniPlayerNavigatorkey.currentState!;
          if (!navigatorState.canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
            return true;
          }
          navigatorState.pop();
          return false;
        },
        child: Stack(
          children: [
            Navigator(
              key: miniPlayerNavigatorkey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                settings: settings,
                builder: (context) => DefaultTabController(
                  length: 5,
                  child: Scaffold(
                    appBar: AppBar(
                      leading: BackButton(
                        onPressed: () {
                          log('popp');
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                      leadingWidth: 30,
                      title: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          'assets/pod-cast-logo-round.png',
                          width: 40,
                          height: 40,
                        ),
                        title: Text('Podcasts'),
                        subtitle: Text(text),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(icon: const Icon(Icons.trending_up)),
                          Tab(icon: const Icon(FontAwesomeIcons.rss)),
                          Tab(icon: const Icon(Icons.category)),
                          Tab(icon: const Icon(Icons.music_note)),
                          Tab(icon: const Icon(Icons.live_tv)),
                        ],
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            var screen = PodCastSearch(appData: widget.appData);
                            var route =
                                MaterialPageRoute(builder: (c) => screen);
                            Navigator.of(context).push(route);
                          },
                          icon: Icon(Icons.search),
                        ),
                        _postPodcastButton(widget.appData)
                      ],
                    ),
                    body: SafeArea(
                      child: Stack(
                        children: [
                          TabBarView(
                            controller: _tabController,
                            children: [
                              PodcastFeedsBody(
                                  future: trendingFeeds,
                                  appData: widget.appData),
                              _rssPodcastTab(context),
                              PodcastCategoriesBody(
                                appData: widget.appData,
                                future: categories,
                              ),
                              PodcastFeedsBody(
                                  future: recentFeeds, appData: widget.appData),
                              PodcastFeedsBody(
                                  future: liveFeeds, appData: widget.appData),
                            ],
                          ),
                          Consumer<PodcastPlayerController>(
                            builder: (context, value, child) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom: value.episodes.isEmpty ? 0 : 65.0),
                                child: _fabContainer(),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Consumer<PodcastPlayerController>(
                builder: (context, value, child) {
                  return Miniplayer(
                    controller: value.miniplayerController,
                    minHeight: value.episodes.isEmpty ? 0 : 65,
                    maxHeight: MediaQuery.of(context).size.height,
                    builder: (height, percentage) {
                      if (value.episodes.isEmpty) {
                        return SizedBox.shrink();
                      } else {
                        return NewPodcastEpidosePlayer(
                            key: ValueKey(value.episodes.first.id),
                            dragValue: percentage,
                            podcastEpisodes: value.episodes,
                            currentPodcastIndex: value.index);
                      }
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _postPodcastButton(HiveUserData userData) {
    return Visibility(
      visible: userData.username != null,
      child: IconButton(
        color: Theme.of(context).primaryColorLight,
        onPressed: () {
          var route = MaterialPageRoute(
              builder: (c) => PodcastUploadScreen(data: widget.appData));
          Navigator.of(context).push(route);
        },
        icon: Icon(Icons.add),
      ),
    );
  }

  Column _rssPodcastTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 15, right: 15),
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)))),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddRssPodcast(),
                  ),
                );
              },
              child: Text(
                "Follow a podcast by URL",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              )),
        ),
        Expanded(
          child: Consumer<PodcastController>(
            builder: (context, myType, child) {
              return LikedPodcasts(
                appData: widget.appData,
                showAppBar: false,
                filterOnlyRssPodcasts: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _fabContainer() {
    if (!isMenuOpen) {
      return FabCustom(
        icon: Icons.bolt,
        onTap: () {
          setState(() {
            isMenuOpen = true;
          });
        },
      );
    }
    return FabOverlay(
      items: _fabItems(),
      onBackgroundTap: () {
        setState(() {
          isMenuOpen = false;
        });
      },
    );
  }

  List<FabOverItemData> _fabItems() {
    var search = FabOverItemData(
      displayName: 'Search',
      icon: Icons.search,
      onTap: () {
        setState(() {
          isMenuOpen = false;
          var screen = PodCastSearch(appData: widget.appData);
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(miniPlayerNavigatorkey.currentState!.context)
              .push(route);
        });
      },
    );
    var favourites = FabOverItemData(
      displayName: 'Bookmarks',
      icon: Icons.bookmarks,
      onTap: () {
        setState(() {
          isMenuOpen = false;
          var screen = LikedPodcasts(appData: widget.appData);
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(miniPlayerNavigatorkey.currentState!.context)
              .push(route);
        });
      },
    );
    var downloaded = FabOverItemData(
      displayName: 'Downloaded Podcast Episode',
      icon: Icons.download_rounded,
      onTap: () {
        setState(() {
          isMenuOpen = false;
          var screen = LocalPodcastEpisode(
            appData: widget.appData,
          );
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(miniPlayerNavigatorkey.currentState!.context)
              .push(route);
        });
      },
    );
    var close = FabOverItemData(
      displayName: 'Close',
      icon: Icons.close,
      onTap: () {
        setState(() {
          isMenuOpen = false;
        });
      },
    );
    var fabItems = [downloaded, favourites, search, close];

    return fabItems;
  }
}
