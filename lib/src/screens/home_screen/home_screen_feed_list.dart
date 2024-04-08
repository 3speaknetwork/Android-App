import 'dart:async';
import 'dart:developer';

import 'package:acela/src/global_provider/image_resolution_provider.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/feed_item_grid_view.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/new_feed_list_item.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/widgets/box_loading/video_feed_loader.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:flutter/material.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:provider/provider.dart';

enum HomeScreenFeedType {
  userFeed,
  trendingFeed,
  newUploads,
  firstUploads,
  userChannelFeed,
  userChannelShorts,
  community,
  trendingTag,
}

class HomeScreenFeedList extends StatefulWidget {
  const HomeScreenFeedList(
      {Key? key,
      required this.appData,
      required this.feedType,
      this.owner,
      this.community,
      this.showVideo = true,
      this.onEmptyDataCallback});

  final HiveUserData appData;
  final HomeScreenFeedType feedType;
  final String? owner;
  final String? community;
  final bool showVideo;
  final VoidCallback? onEmptyDataCallback;

  @override
  State<HomeScreenFeedList> createState() => _HomeScreenFeedListState();
}

class _HomeScreenFeedListState extends State<HomeScreenFeedList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<GQLFeedItem> items = [];
  int pageLimit = 50;
  var firstPageLoaded = false;
  var isPageEnded = false;
  var isLoading = false;
  var hasFailed = false;
  final _scrollController = ScrollController();
  int inViewIndex = 0;
  bool viewOnStart = true;
  bool viewOnEnd = false;
  bool isUserScrolling = false;
  Timer loadVideoOnStoppedScrolling =
      Timer(const Duration(milliseconds: 1), () {});

  @override
  void initState() {
    super.initState();
    loadFeed(false);
    _scrollController.addListener(() {
      if (_scrollController.offset == 0) {
        if (!viewOnStart) {
          setState(() {
            viewOnStart = true;
            _setInViewIndex(0);
          });
        }
      } else {
        if (viewOnStart) {
          setState(() {
            viewOnStart = false;
          });
        }
      }
      if (_scrollController.offset !=
          _scrollController.position.maxScrollExtent) {}
      if (viewOnEnd) {
        setState(() {
          viewOnEnd = false;
        });
      }
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isPageEnded) {
        loadFeed(false);
      }
    });
  }

  Future<List<GQLFeedItem>> loadWith(bool firstPage) {
    try {
      switch (widget.feedType) {
        case HomeScreenFeedType.trendingTag:
          return GQLCommunicator().getTrendingTagFeed(
            widget.owner ?? 'threespeak',
            false,
            firstPage ? 0 : items.length,
            widget.appData.language,
          );
        case HomeScreenFeedType.trendingFeed:
          return GQLCommunicator().getTrendingFeed(
              false, firstPage ? 0 : items.length, widget.appData.language);
        case HomeScreenFeedType.newUploads:
          return GQLCommunicator().getNewUploadsFeed(
              false, firstPage ? 0 : items.length, widget.appData.language);
        case HomeScreenFeedType.firstUploads:
          return GQLCommunicator().getFirstUploadsFeed(
              false, firstPage ? 0 : items.length, widget.appData.language);
        case HomeScreenFeedType.userFeed:
          return GQLCommunicator().getMyFeed(
              widget.appData.username ?? 'sagarkothari88',
              false,
              firstPage ? 0 : items.length,
              widget.appData.language);
        case HomeScreenFeedType.userChannelFeed:
          return GQLCommunicator().getUserFeed(
              [widget.owner ?? 'sagarkothari88'],
              false,
              firstPage ? 0 : items.length,
              widget.appData.language);
        case HomeScreenFeedType.userChannelShorts:
          return GQLCommunicator().getUserFeed(
              [widget.owner ?? 'sagarkothari88'],
              true,
              firstPage ? 0 : items.length,
              widget.appData.language);
        case HomeScreenFeedType.community:
          return GQLCommunicator().getCommunity(
              widget.community ?? 'hive-181335',
              true,
              firstPage ? 0 : items.length,
              widget.appData.language);
      }
    } catch (e) {
      hasFailed = true;
      throw e;
    }
  }

  void loadFeed(bool reset) async {
    log('loading');
    if (isLoading) return;
    if (!firstPageLoaded) {
      setState(() {
        isLoading = true;
        firstPageLoaded = false;
      });
      var newItems = await loadWith(true);
      setState(() {
        if (newItems.length < pageLimit - 1) {
          isPageEnded = true;
        }
        items = newItems;
        if (items.isEmpty && widget.onEmptyDataCallback != null) {
          widget.onEmptyDataCallback!();
        }
        isLoading = false;
        firstPageLoaded = true;
      });
    } else {
      setState(() {
        isLoading = true;
        if (reset) {
          firstPageLoaded = false;
          isPageEnded = false;
        }
      });
      var newItems = await loadWith(reset);
      setState(() {
        if (newItems.length < pageLimit - 1) {
          isPageEnded = true;
        }
        if (newItems.isNotEmpty) {
          newItems.removeAt(0);
        }
        items = items + newItems;
        isLoading = false;
        firstPageLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = MediaQuery.of(context).size.shortestSide > 600;
    super.build(context);
    var screenWidth = MediaQuery.of(context).size.width;
    if (isLoading && !firstPageLoaded) {
      return VideoFeedLoader(
        isGridView: isGridView,
      );
    } else if (hasFailed) {
      return RetryScreen(
        onRetry: () async {
          loadFeed(true);
        },
        error: 'Something went wrong. Try again.',
      );
    } else {
      if (items.isEmpty) {
        return Center(
          child: Column(
            children: [
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  widget.feedType == HomeScreenFeedType.userFeed
                      ? 'Please follow more people to see videos they publish.'
                      : 'We did not find anything to show.\nTap on Reload button to try again.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5,),
              ElevatedButton(
                onPressed: () {
                  loadFeed(true);
                },
                child: Text('Reload'),
              ),
              Spacer(),
            ],
          ),
        );
      } else {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (isGridView) {
              return FeedItemGridView(
                  scrollController: _scrollController,
                  nextPageLoader: _loadNextPageWidget(),
                  screenWidth: screenWidth,
                  items: items,
                  appData: widget.appData);
            } else {
              return _listView();
            }
          },
        );
      }
    }
  }

  NotificationListener<ScrollNotification> _listView() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollStartStopNotification,
      child: RefreshIndicator(
        onRefresh: () async {
          loadFeed(true);
        },
        child: InViewNotifierList(
          scrollDirection: Axis.vertical,
          controller: _scrollController,
          initialInViewIds: ['0'],
          isInViewPortCondition:
              (double deltaTop, double deltaBottom, double viewPortDimension) {
            return deltaTop < (0.5 * viewPortDimension) &&
                deltaBottom > (0.5 * viewPortDimension);
          },
          itemCount: items.length,
          onListEndReached: () {
            if (!viewOnEnd) {
              setState(() {
                viewOnEnd = true;
              });
            }

            _setInViewIndex(items.length - 1);
          },
          builder: (context, index) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return InViewNotifierWidget(
                  id: '$index',
                  builder: (context, isInView, child) {
                    if (isInView && !viewOnStart && !viewOnEnd) {
                      _setInViewIndex(index);
                    }
                    var item = items[index];
                    return Selector<SettingsProvider, bool>(
                      selector: (_, myType) => myType.autoPlayVideo,
                      builder: (context, autoPlay, child) {
                        return Column(
                          children: [
                            NewFeedListItem(
                              key: ValueKey(index),
                              showVideo: (index == inViewIndex &&
                                      !isUserScrolling &&
                                      widget.showVideo) &&
                                  autoPlay,
                              thumbUrl: item.spkvideo?.thumbnailUrl ?? '',
                              author: item.author?.username ?? '',
                              title: item.title ?? '',
                              createdAt: item.createdAt ?? DateTime.now(),
                              duration: item.spkvideo?.duration ?? 0.0,
                              comments: item.stats?.numComments ?? 0,
                              hiveRewards: item.stats?.totalHiveReward,
                              votes: item.stats?.numVotes,
                              views: 0,
                              permlink: item.permlink ?? '',
                              onTap: () {},
                              onUserTap: () {},
                              item: item,
                              appData: widget.appData,
                            ),
                            Visibility(
                                visible:
                                    index == items.length - 1 && !isPageEnded,
                                child: _loadNextPageWidget())
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Visibility _loadNextPageWidget() {
    return Visibility(
      visible: !isPageEnded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  bool _onScrollStartStopNotification(ScrollNotification scrollNotification) {
    if (scrollNotification is ScrollStartNotification) {
      if (!isUserScrolling) {
        setState(() {
          isUserScrolling = true;
        });
      }
      return true;
    } else if (scrollNotification is ScrollEndNotification) {
      if (isUserScrolling) {
        loadVideoOnStoppedScrolling.cancel();
        const duration = Duration(seconds: 1);
        loadVideoOnStoppedScrolling = Timer(duration, () {
          setState(() {
            isUserScrolling = false;
          });
        });
      }
      return true;
    } else {
      return true;
    }
  }

  void _setInViewIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (inViewIndex != index) {
        setState(() {
          inViewIndex = index;
        });
      }
    });
  }
}
