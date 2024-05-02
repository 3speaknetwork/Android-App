import 'package:acela/src/models/podcast/trending_podcast_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LikedPodcasts extends StatefulWidget {
  const LikedPodcasts(
      {Key? key,
      required this.appData,
      this.showAppBar = true,
      this.playOnMiniPlayer = true,
      this.filterOnlyRssPodcasts = false})
      : super(key: key);

  final HiveUserData appData;
  final bool showAppBar;
  final bool playOnMiniPlayer;
  final bool filterOnlyRssPodcasts;

  @override
  State<LikedPodcasts> createState() => _LikedPodcastsState();
}

class _LikedPodcastsState extends State<LikedPodcasts> {
  @override
  Widget build(BuildContext context) {
    final List<PodCastFeedItem> items = context
        .read<PodcastController>()
        .getLikedPodcast(filterOnlyRssPodcasts: widget.filterOnlyRssPodcasts);
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text("Liked Podcasts"),
            )
          : null,
      body: items.isEmpty
          ? Center(
              child: Text(widget.filterOnlyRssPodcasts
                  ? ""
                  : "Liked Podcasts is Empty"))
          : ListView.separated(
              itemBuilder: (c, i) {
                return Dismissible(
                  key: Key(items[i].id!),
                  background: Center(child: Text("Delete")),
                  onDismissed: (direction) {
                    context
                        .read<PodcastController>()
                        .storeLikedPodcastLocally(items[i]);
                    showSnackBar("Podcast ${items[i].title} is removed");
                  },
                  child: PodcastFeedItemWidget(
                    playOnMiniPlayer: widget.playOnMiniPlayer,
                    showLikeButton: false,
                    appData: widget.appData,
                    item: items[i],
                  ),
                );
              },
              separatorBuilder: (c, i) => const Divider(height: 0),
              itemCount: items.length,
            ),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      duration: Duration(seconds: 3),
    ));
  }
}
