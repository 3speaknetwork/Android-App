import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/models/podcast/trending_podcast_response.dart';
import 'package:acela/src/screens/podcast/controller/podcast_episodes_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_player_controller.dart';
import 'package:acela/src/screens/podcast/view/podcast_episodes/podcast_episodes_appbar.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:audio_service/audio_service.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class PodcastEpisodesView extends StatefulWidget {
  const PodcastEpisodesView(
      {Key? key, required this.feedItem, required this.playOnMiniPlayer})
      : super(key: key);

  final PodCastFeedItem feedItem;
  final bool playOnMiniPlayer;

  @override
  State<PodcastEpisodesView> createState() => _PodcastEpisodesViewState();
}

class _PodcastEpisodesViewState extends State<PodcastEpisodesView> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (context) => PodcastEpisodesController(
          isRss: widget.feedItem.rssUrl != null,
          id: widget.feedItem.rssUrl != null
              ? widget.feedItem.rssUrl!
              : "${widget.feedItem.id ?? 227573}"),
      builder: (context, child) {
        final controller = context.read<PodcastEpisodesController>();
        return Scaffold(
          appBar: PodcastEpisodesAppbar(
            scrollController: scrollController,
            title: widget.feedItem.title,
            image: widget.feedItem.image,
          ),
          body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                child: Selector<PodcastEpisodesController, ViewState>(
                  selector: (_, provider) => provider.viewState,
                  builder: (context, state, child) {
                    if (state == ViewState.data) {
                      return _data(controller.items, theme, context);
                    } else if (state == ViewState.empty) {
                      return RetryScreen(
                          error: "No episodes found",
                          onRetry: () => controller.refresh());
                    } else if (state == ViewState.error) {
                      return RetryScreen(
                          error: "Something went wrong",
                          onRetry: () => controller.refresh());
                    } else {
                      return LoadingScreen(
                          title: 'Loading', subtitle: 'Please wait..');
                    }
                  },
                )),
          ),
        );
      },
    );
  }

  ListView _data(
      List<PodcastEpisode> episodes, ThemeData theme, BuildContext context) {
    final PodcastPlayerController playerController =
        context.read<PodcastPlayerController>();
    return ListView.builder(
      controller: scrollController,
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        PodcastEpisode item = episodes[index];
        return Padding(
          padding:
              EdgeInsets.only(bottom: index == episodes.length - 1 ? 65.0 : 0),
          child: Column(
            children: [
              if (index == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CachedImage(
                              imageHeight: 125,
                              imageWidth: 125,
                              borderRadius: 18,
                              imageUrl: widget.feedItem.networkImage),
                          SizedBox(
                            width: 15,
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                widget.feedItem.title ?? "",
                                maxLines: 5,
                                minFontSize: 13,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              AutoSizeText(
                                widget.feedItem.author ?? "",
                                maxLines: 2,
                                maxFontSize: 13,
                                minFontSize: 11,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ))
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: FilledButton.icon(
                          onPressed: () => playerController.onDefaultPlay(
                              context,episodes, widget.playOnMiniPlayer),
                          style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              backgroundColor: theme.primaryColorLight),
                          label: Text(
                            "Play",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          icon: Icon(Icons.play_arrow),
                        ),
                      )
                    ],
                  ),
                ),
              ListTile(
                onTap: () => playerController.onTapEpisode(
                    index, context, episodes, widget.playOnMiniPlayer),
                trailing: StreamBuilder<MediaItem?>(
                    stream: GetAudioPlayer().audioHandler.mediaItem,
                    builder: (context, snapshot) {
                      MediaItem? mediaItem = snapshot.data;
                      return mediaItem != null &&
                              mediaItem.id == item.enclosureUrl
                          ? SizedBox(
                              height: 30,
                              width: 30,
                              child: SpinKitWave(
                                itemCount: 4,
                                type: SpinKitWaveType.center,
                                size: 15,
                                color: theme.primaryColorLight,
                              ),
                            )
                          : Icon(Icons.play_circle_outline_outlined);
                    }),
                leading: CachedImage(
                  imageUrl: item.networkImage,
                  imageHeight: 48,
                  imageWidth: 48,
                  loadingIndicatorSize: 25,
                ),
                title: Text(
                  item.title!,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: item.duration != null || item.episode != null
                    ? Row(
                        children: [
                          if (item.episode != null)
                            Text(
                              "#${item.episode} ${item.duration != null ? "  •  " : ""} ",
                              style: TextStyle(fontSize: 11),
                            ),
                          if (item.duration != null)
                            Text(
                              formatDuration(item.duration!),
                              style: TextStyle(fontSize: 11),
                            ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  String formatDuration(int seconds) {
    Duration duration = Duration(seconds: seconds);

    if (duration.inHours < 1) {
      return '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}
