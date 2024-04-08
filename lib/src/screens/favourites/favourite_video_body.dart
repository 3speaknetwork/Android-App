import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/new_feed_list_item.dart';
import 'package:flutter/material.dart';

class FavouriteVideoBody extends StatefulWidget {
  const FavouriteVideoBody({Key? key, required this.appData}) : super(key: key);

  final HiveUserData appData;

  @override
  State<FavouriteVideoBody> createState() => _FavouriteVideoBodyState();
}

class _FavouriteVideoBodyState extends State<FavouriteVideoBody> {
  final VideoFavoriteProvider dataProvider = VideoFavoriteProvider();

  @override
  Widget build(BuildContext context) {
    List<GQLFeedItem> items = dataProvider.getLikedVideos();
    return items.isNotEmpty
        ? ListView.builder(
            itemBuilder: (c, i) {
              var item = items[i];
              return NewFeedListItem(
                  onFavouriteRemoved: () {
                    setState(() {});
                  },
                  thumbUrl: item.spkvideo?.thumbnailUrl ?? '',
                  author: item.author?.username ?? '',
                  title: item.title ?? '',
                  createdAt: item.createdAt ?? DateTime.now(),
                  duration: item.spkvideo?.duration ?? 0.0,
                  comments: item.stats?.numComments,
                  hiveRewards: item.stats?.totalHiveReward,
                  votes: item.stats?.numVotes,
                  views: 0,
                  permlink: item.permlink ?? '',
                  onTap: () {},
                  onUserTap: () {},
                  item: item,
                  appData: widget.appData);
            },
            itemCount: items.length % 50 == 0 ? items.length + 1 : items.length,
          )
        : Center(
            child: Text("No Bookmarked vidoes found"),
          );
  }
}
