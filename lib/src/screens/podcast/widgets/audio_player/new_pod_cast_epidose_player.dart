import 'dart:async';
import 'dart:developer';
import 'dart:ui';

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
import 'package:acela/src/screens/podcast/widgets/podcast_player_widgets/progress_bar.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class NewPodcastEpidosePlayer extends StatefulWidget {
  const NewPodcastEpidosePlayer(
      {Key? key,
      required this.podcastEpisodes,
      required this.dragValue,
      required this.currentPodcastIndex})
      : super(key: key);

  final List<PodcastEpisode> podcastEpisodes;
  final int currentPodcastIndex;
  final double dragValue;

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
    currentPodcastIndex = widget.currentPodcastIndex;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    return ChangeNotifierProvider.value(
      value: chapterController,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (originalImage != null && originalImage!.isNotEmpty)
              CachedImage(
                imageUrl: originalImage,
              ),
            if (originalImage != null && originalImage!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            Positioned.fill(
                child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                theme.primaryColorDark,
                theme.primaryColorDark.withOpacity(0.3)
              ])),
            )),
            // if (widget.dragValue < 0.5)
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Visibility(
                  maintainAnimation: true,
                  maintainSize: true,
                  maintainState: true,
                  visible: widget.dragValue < 0.5,
                  child: PodcastProgressBar(
                      duration: currentPodcastEpisode.duration,
                      positionStream: _positionDataStream),
                )),
            StreamBuilder<MediaItem?>(
              stream: _audioHandler.mediaItem,
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
                        _audioHandler.shouldPlayVideo()
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                    child: ValueListenableBuilder<double?>(
                                  valueListenable:
                                      _audioHandler.aspectRatioNotifier,
                                  builder: (context, aspectRatio, child) {
                                    return AspectRatio(
                                        aspectRatio: aspectRatio ?? 1.5,
                                        child: child);
                                  },
                                  child: VideoPlayer(
                                      _audioHandler.videoPlayerController!),
                                )),
                              )
                            : Transform.translate(
                                offset: Offset(
                                  lerpDouble(-150, 0, widget.dragValue) ?? 0,
                                  lerpDouble(-152.5, 0, widget.dragValue) ?? 0,
                                ),
                                child: Container(
                                    height: lerpDouble(
                                            50,
                                            MediaQuery.of(context).size.height *
                                                0.45,
                                            widget.dragValue) ??
                                        0,
                                    width: lerpDouble(
                                            50,
                                            MediaQuery.of(context).size.width *
                                                0.85,
                                            widget.dragValue) ??
                                        0,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 30),
                                    // constraints: BoxConstraints(
                                    //     maxHeight: MediaQuery.of(context)
                                    //             .size
                                    //             .height *
                                    //         0.45),
                                    child: Selector<PodcastChapterController,
                                        String?>(
                                      selector: (_, myType) => myType.image,
                                      builder: (context, chapterImage, child) {
                                        return CachedImage(
                                          imageUrl:
                                              chapterImage ?? originalImage,
                                          imageHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.45,
                                        );
                                      },
                                    )),
                              ),
                        Spacer(),
                        AnimatedOpacity(
                          opacity: widget.dragValue == 1
                              ? 1
                              : widget.dragValue.clamp(0, 0.5),
                          duration: Duration(milliseconds: 150),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 10),
                                child: Column(
                                  children: [
                                    _title(screenWidth * 0.85),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      currentPodcastEpisode.datePublishedPretty
                                          .toString(),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              userToolbar(theme),
                              _slider(),
                              Gap(10),
                              ControlButtons(
                                _audioHandler,
                                chapterController: chapterController,
                                podcastEpisode: currentPodcastEpisode,
                                showSkipPreviousButtom:
                                    widget.podcastEpisodes.length > 1,
                                positionStream:
                                    _positionDataStream.asBroadcastStream(),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (widget.dragValue < 0.5)
              AnimatedPositioned(
                top: lerpDouble(10, 0, widget.dragValue),
                left: lerpDouble(80, 20, widget.dragValue),
                right: 10,
                duration: Duration(milliseconds: 100),
                child: AnimatedOpacity(
                  opacity: (lerpDouble(1, 6, widget.dragValue * (-0.5)) ?? 0)
                      .clamp(0, 1),
                  duration: Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0, right: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: _title(screenWidth * 0.75,
                                height: 15, fontSize: 14)),
                        ControlButtons(
                          _audioHandler,
                          smallSize: true,
                          chapterController: chapterController,
                          podcastEpisode: currentPodcastEpisode,
                          showSkipPreviousButtom:
                              widget.podcastEpisodes.length > 1,
                          positionStream:
                              _positionDataStream.asBroadcastStream(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PodcastPlayerSlider _slider() {
    return PodcastPlayerSlider(
        episode: currentPodcastEpisode,
        chapterController: chapterController,
        audioPlayerHandler: _audioHandler,
        positionDataStream: _positionDataStream,
        currentPodcastEpisodeDuration: currentPodcastEpisode.duration);
  }

  Selector<PodcastChapterController, String?> _title(double maxwidth,
      {double fontSize = 20, double height = 25}) {
    return Selector<PodcastChapterController, String?>(
      selector: (_, myType) => myType.title,
      builder: (context, chapterTitle, child) {
        return SizedBox(
          width: maxwidth,
          height: height,
          child: Utilities.textLines(
                      chapterTitle ?? originalTitle,
                      TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize),
                      maxwidth,
                      3) >
                  1
              ? Marquee(
                  text: chapterTitle ?? originalTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: fontSize),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 50,
                  velocity: 40.0,
                  pauseAfterRound: const Duration(milliseconds: 1000),
                  showFadingOnlyWhenScrolling: true,
                  fadingEdgeStartFraction: 0.1,
                  fadingEdgeEndFraction: 0.1,
                  startPadding: 0.0,
                  accelerationDuration: const Duration(seconds: 2),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: const Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                )
              : Text(
                  chapterTitle ?? originalTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: fontSize),
                ),
        );
      },
    );
  }

  Widget userToolbar(ThemeData theme) {
    Color iconColor = theme.primaryColorLight;
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
        },
      ),
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
