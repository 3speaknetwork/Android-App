import 'dart:async';
import 'dart:developer';

import 'package:acela/src/models/podcast/podcast_episode_chapters.dart';
import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/screens/podcast/controller/podcast_chapters_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/action_tools.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/screens/podcast/widgets/favourite.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_info_description.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_player_widgets/control_buttons.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_player_widgets/download_podcast_button.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_player_widgets/podcast_player_slider.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class NewPodcastEpidosePlayer extends StatefulWidget {
  const NewPodcastEpidosePlayer({Key? key, required this.podcastEpisodes})
      : super(key: key);

  final List<PodcastEpisode> podcastEpisodes;

  @override
  State<NewPodcastEpidosePlayer> createState() =>
      _NewPodcastEpidosePlayerState();
}

class _NewPodcastEpidosePlayerState extends State<NewPodcastEpidosePlayer> {
  final _audioHandler = GetAudioPlayer().audioHandler;
  int currentPodcastIndex = 0;

  late final StreamSubscription queueSubscription;
  late final PodcastController podcastController;
  late PodcastEpisode currentPodcastEpisode;
  late PodcastChapterController chapterController;
  List<PodcastEpisodeChapter>? chapters;
  late String originalTitle;
  late String? originalImage;
  late Timer timer;

  Stream<Duration> get _bufferedPositionStream => _audioHandler.playbackState
      .map((state) => state.bufferedPosition)
      .distinct();

  Stream<Duration?> get _durationStream =>
      _audioHandler.mediaItem.map((item) => item?.duration).distinct();

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          AudioService.position,
          _bufferedPositionStream,
          _durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  void initState() {
    super.initState();
    currentPodcastEpisode = widget.podcastEpisodes[currentPodcastIndex];
    log(currentPodcastEpisode.enclosureUrl!);
    _setUpVideo();
    podcastController = context.read<PodcastController>();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      writeCurrentDurationLocal();
    });
    podcastController.isDurationContinuing = true;
    originalImage = currentPodcastEpisode.image;
    originalTitle = currentPodcastEpisode.title!;
    // TO-DO: Ram to handle chapters for offline player
    // if (currentPodcastEpisode.enclosureUrl != null && currentPodcastEpisode.enclosureUrl!.startsWith("http")) {
    chapterController = PodcastChapterController(
        chapterUrl: currentPodcastEpisode.chaptersUrl,
        totalDuration: currentPodcastEpisode.duration ?? 0,
        audioPlayerHandler: _audioHandler);
    // }
    queueSubscription = _audioHandler.queueState.listen((event) {});
    queueSubscription.onData((data) {
      _onEpisodeChange(data);
    });
  }

  void _setUpVideo() {
    if (!currentPodcastEpisode.isAudio) {
      _audioHandler.isVideo = true;
      _audioHandler.setUpVideoController(currentPodcastEpisode.enclosureUrl!);
    } else {
      _audioHandler.isVideo = false;
    }
  }

  void writeCurrentDurationLocal() async {
    int seconds = await _audioHandler.currentPosition();
    if (seconds > 0) {
      context.read<PodcastController>().writeDurationOfEpisode(
          currentPodcastEpisode.id!,
          currentPodcastEpisode.enclosureUrl!,
          seconds);
    }
  }

  void _onEpisodeChange(data) {
    QueueState queueState = data as QueueState;
    if (currentPodcastIndex != queueState.queueIndex) {
      setState(() {
        currentPodcastIndex = queueState.queueIndex ?? 0;
        currentPodcastEpisode = widget.podcastEpisodes[currentPodcastIndex];
        podcastController.isDurationContinuing = true;
        _setUpVideo();
        timer.cancel();
        timer = Timer.periodic(Duration(seconds: 1), (t) {
          writeCurrentDurationLocal();
        });
        // if (currentPodcastEpisode.enclosureUrl != null && currentPodcastEpisode.enclosureUrl!.startsWith("http")) {
        chapterController = PodcastChapterController(
            chapterUrl: currentPodcastEpisode.chaptersUrl,
            totalDuration: currentPodcastEpisode.duration ?? 0,
            audioPlayerHandler: _audioHandler);
        // }
        originalTitle = currentPodcastEpisode.title!;
        originalImage = currentPodcastEpisode.image;
      });
    }
  }

  @override
  void dispose() {
    queueSubscription.cancel();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: chapterController,
      child: Scaffold(
        body: SafeArea(
          child: StreamBuilder<MediaItem?>(
            stream: _audioHandler.mediaItem,
            builder: (context, snapshot) {
              final mediaItem = snapshot.data;
              if (mediaItem == null) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _audioHandler.shouldPlayVideo()
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: Center(
                              child: ValueListenableBuilder<double?>(
                            valueListenable: _audioHandler.aspectRatioNotifier,
                            builder: (context, aspectRatio, child) {
                              return AspectRatio(
                                  aspectRatio: aspectRatio ?? 1.5,
                                  child: child);
                            },
                            child: VideoPlayer(
                                _audioHandler.videoPlayerController!),
                          )),
                        )
                      : Container(
                          constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.45),
                          child: Selector<PodcastChapterController, String?>(
                            selector: (_, myType) => myType.image,
                            builder: (context, chapterImage, child) {
                              return CachedImage(
                                imageUrl: chapterImage ?? originalImage,
                                imageHeight:
                                    MediaQuery.of(context).size.height * 0.45,
                              );
                            },
                          )),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 10),
                    child: Column(
                      children: [
                        Selector<PodcastChapterController, String?>(
                          selector: (_, myType) => myType.title,
                          builder: (context, chapterTitle, child) {
                            return Text(
                              chapterTitle ?? originalTitle,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            );
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          currentPodcastEpisode.datePublishedPretty.toString(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  userToolbar(),
                  PodcastPlayerSlider(
                      episode: currentPodcastEpisode,
                      chapterController: chapterController,
                      audioPlayerHandler: _audioHandler,
                      positionDataStream: _positionDataStream,
                      currentPodcastEpisodeDuration:
                          currentPodcastEpisode.duration),
                  ControlButtons(
                    _audioHandler,
                    chapterController: chapterController,
                    podcastEpisode: currentPodcastEpisode,
                    showSkipPreviousButtom: widget.podcastEpisodes.length > 1,
                    positionStream: _positionDataStream.asBroadcastStream(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget userToolbar() {
    Color iconColor = Colors.lightBlue;
    List<Widget> tools = [
      IconButton(
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        icon: Icon(Icons.info_outline, color: iconColor),
        onPressed: () {
          _onInfoButtonTap();
        },
      ),
      IconButton(
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        icon: Icon(Icons.share, color: iconColor),
        onPressed: () {
          Share.share(currentPodcastEpisode.enclosureUrl ?? '');
        },
      ),
      DownloadPodcastButton(
        color: iconColor,
        episode: currentPodcastEpisode,
      ),
      FavouriteWidget(
          toastType: "Podcast Episode",
          disablePadding: true,
          iconColor: iconColor,
          isLiked: podcastController
              .isLikedPodcastEpisodePresentLocally(currentPodcastEpisode),
          onAdd: () {
            podcastController
                .storeLikedPodcastEpisodeLocally(currentPodcastEpisode);
          },
          onRemove: () {
            podcastController
                .storeLikedPodcastEpisodeLocally(currentPodcastEpisode);
          }),
      IconButton(
        onPressed: () {
          _onTapPodcastHistory();
        },
        icon: Icon(
          Icons.list,
          color: iconColor,
        ),
      )
    ];
    // if (context.read<HiveUserData>().username != null) {
    //   tools.insert(
    //     3,
    //     IconButton(
    //       constraints: const BoxConstraints(),
    //       padding: EdgeInsets.zero,
    //       icon: Icon(CupertinoIcons.gift_fill, color: iconColor),
    //       onPressed: () {
    //         Navigator.of(context).push(MaterialPageRoute(
    //           builder: (context) => const ValueForValueView(),
    //         ));
    //       },
    //     ),
    //   );
    // }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tools,
    );
  }

  void _onInfoButtonTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      isDismissible: true,
      builder: (context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PodcastInfoDescroption(
                title: currentPodcastEpisode.title,
                description: currentPodcastEpisode.description));
      },
    );
  }

  void _onTapPodcastHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      isDismissible: true,
      builder: (context) {
        return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Scaffold(
              appBar: AppBar(
                title: Text("Podcast Episodes"),
              ),
              body: ListView.builder(
                itemCount: widget.podcastEpisodes.length,
                itemBuilder: (context, index) {
                  PodcastEpisode item = widget.podcastEpisodes[index];
                  return ListTile(
                    onTap: () {
                      _audioHandler.skipToQueueItem(index);
                      Navigator.pop(context);
                    },
                    trailing: Icon(Icons.play_circle_outline_outlined),
                    leading: CachedImage(
                      imageUrl: item.image,
                      imageHeight: 48,
                      imageWidth: 48,
                      loadingIndicatorSize: 25,
                    ),
                    title: Text(
                      item.title!,
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                },
              ),
            ));
      },
    );
  }
}
