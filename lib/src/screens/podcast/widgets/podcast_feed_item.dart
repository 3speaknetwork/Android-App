import 'package:acela/src/models/podcast/trending_podcast_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/view/podcast_episodes/podcast_episodes_view.dart';
import 'package:acela/src/screens/podcast/widgets/favourite.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastFeedItemWidget extends StatefulWidget {
  const PodcastFeedItemWidget(
      {Key? key,
      required this.item,
      required this.appData,
      this.showLikeButton = true,
      this.playOnMiniPlayer = true})
      : super(key: key);

  final PodCastFeedItem item;
  final HiveUserData appData;
  final bool showLikeButton;
  final bool playOnMiniPlayer;

  @override
  State<PodcastFeedItemWidget> createState() => _PodcastFeedItemWidgetState();
}

class _PodcastFeedItemWidgetState extends State<PodcastFeedItemWidget> {
  @override
  Widget build(BuildContext context) {
    var title = widget.item.title ?? 'No title';
    var desc = '';
    // desc = "$desc${(widget.item.categories?.values ?? []).join(", ")}";
    final podcastController = context.read<PodcastController>();
    return ListTile(
      dense: true,
      leading: CachedImage(
        imageUrl: widget.item.networkImage,
        imageHeight: 48,
        imageWidth: 48,
        loadingIndicatorSize: 25,
      ),
      title: Text(title),
      subtitle: Text(widget.item.author ?? ""),
      trailing: Visibility(
        visible: widget.showLikeButton,
        child: FavouriteWidget(
            toastType: "Podcast",
            isLiked:
                podcastController.isLikedPodcastPresentLocally(widget.item),
            onAdd: () {
              podcastController.storeLikedPodcastLocally(widget.item);
            },
            onRemove: () {
              podcastController.storeLikedPodcastLocally(widget.item);
            }),
      ),
      onTap: () {
        var screen = PodcastEpisodesView(
          feedItem: widget.item,
          playOnMiniPlayer: widget.playOnMiniPlayer,
        );
        var route = MaterialPageRoute(builder: (c) => screen);
        Navigator.of(context).push(route);
      },
    );
  }
}
