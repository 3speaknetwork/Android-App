import 'package:acela/src/screens/stories/story_feed_body.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

enum StoryFeedType {
  cttFeed,
  userFeed,
  trendingFeed,
  newUploads,
  firstUploads,
  userChannelFeed,
  community,
  trendingTag,
}

class StoryFeedList extends StatefulWidget {
  const StoryFeedList({
    Key? key,
    required this.appData,
    required this.feedType,
    this.username,
    this.community,
  });

  final StoryFeedType feedType;
  final HiveUserData appData;
  final String? username;
  final String? community;

  @override
  State<StoryFeedList> createState() => _StoryFeedListState();
}

class _StoryFeedListState extends State<StoryFeedList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<GQLFeedItem> items = [];
  var firstPageLoaded = false;
  var isLoading = false;
  var hasFailed = false;
  CarouselSliderController controller = CarouselSliderController();
  // final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadFeed(false);
  }

  Future<List<GQLFeedItem>> loadWith(bool firstPage) {
    try {
      switch (widget.feedType) {
        case StoryFeedType.trendingTag:
          return GQLCommunicator()
              .getTrendingTagFeed(widget.username ?? 'threespeak', true, firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.cttFeed:
          return GQLCommunicator()
              .getCTTFeed(firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.trendingFeed:
          return GQLCommunicator()
              .getTrendingFeed(true, firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.newUploads:
          return GQLCommunicator()
              .getNewUploadsFeed(true, firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.firstUploads:
          return GQLCommunicator()
              .getFirstUploadsFeed(true, firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.userFeed:
          return GQLCommunicator().getMyFeed(
              widget.appData.username ?? 'sagarkothari88',
              true,
              firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.userFeed:
          return GQLCommunicator().getMyFeed(
            widget.appData.username ?? 'sagarkothari88',
            true,
            firstPage ? 0 : items.length, widget.appData.language
          );
        case StoryFeedType.userChannelFeed:
          return GQLCommunicator().getUserFeed([widget.username ?? 'sagarkothari88'],
              true, firstPage ? 0 : items.length, widget.appData.language);
        case StoryFeedType.community:
          return GQLCommunicator().getCommunity(widget.community ?? 'hive-181335',
              true, firstPage ? 0 : items.length, widget.appData.language);
      }
    } catch (e) {
      hasFailed = true;
      throw e;
    }
  }

  void loadFeed(bool reset) async {
    if (isLoading) return;
    if (!firstPageLoaded) {
      setState(() {
        isLoading = true;
        firstPageLoaded = false;
      });
      var newItems = await loadWith(true);
      setState(() {
        items = newItems;
        isLoading = false;
        firstPageLoaded = true;
      });
    } else {
      setState(() {
        isLoading = true;
        if (reset) {
          firstPageLoaded = false;
        }
      });
      var newItems = await loadWith(reset);
      setState(() {
        items = items + newItems;
        isLoading = false;
        firstPageLoaded = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isLoading && !firstPageLoaded) {
      return LoadingScreen(title: 'Loading', subtitle: 'Please wait');
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
              Text(
                  'We did not find anything to show.\nTap on Reload button to try again.'),
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
        return StoryFeedDataBody(items: items,appData: widget.appData,controller: controller,);
      }
    }
  }
}
