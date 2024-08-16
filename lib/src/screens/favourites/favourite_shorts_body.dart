import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/stories/story_feed_body.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FavouriteShortsBody extends StatefulWidget {
  const FavouriteShortsBody({Key? key, required this.appData})
      : super(key: key);

  final HiveUserData appData;

  @override
  State<FavouriteShortsBody> createState() => _FavouriteShortsBodyState();
}

class _FavouriteShortsBodyState extends State<FavouriteShortsBody> {
  final CarouselSliderController controller = CarouselSliderController();
  final VideoFavoriteProvider dataProvider = VideoFavoriteProvider();
  
  @override
  Widget build(BuildContext context) {
    final List<GQLFeedItem> shorts =
        dataProvider.getLikedVideos(isShorts: true);
    return shorts.isNotEmpty
        ? StoryFeedDataBody(
            onRemoveFavouriteCallback: () {
              setState(() {});
            },
            items: shorts,
            appData: widget.appData,
            controller: controller)
        : Center(
            child: Text("No Bookmarked shorts found"),
          );
  }
}
