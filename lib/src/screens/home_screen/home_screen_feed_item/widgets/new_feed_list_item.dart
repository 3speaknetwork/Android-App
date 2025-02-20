import 'dart:io';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/global_provider/image_resolution_provider.dart';
import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/models/navigation_models/new_video_detail_screen_navigation_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/controller/home_feed_video_controller.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/home_feed_video_full_screen_button.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/home_feed_video_slider.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/home_feed_video_timer.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/mute_unmute_button.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/play_pause_button.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/thumbnail_widget.dart';
import 'package:acela/src/screens/report/widgets/report_pop_up_menu.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/screens/video_details_screen/video_details_screen.dart';
import 'package:acela/src/screens/video_details_screen/video_details_view_model.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:acela/src/widgets/upvote_button.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewFeedListItem extends StatefulWidget {
  const NewFeedListItem(
      {Key? key,
      required this.createdAt,
      required this.duration,
      required this.views,
      required this.thumbUrl,
      required this.author,
      required this.title,
      required this.permlink,
      required this.onTap,
      required this.onUserTap,
      required this.comments,
      required this.votes,
      required this.hiveRewards,
      this.item,
      required this.appData,
      this.showVideo = false,
      this.onFavouriteRemoved,
      this.isGridView = false})
      : super(key: key);

  final DateTime? createdAt;
  final double? duration;
  final int? views;
  final String thumbUrl;
  final String author;
  final String title;
  final String permlink;
  final int? votes;
  final int? comments;
  final double? hiveRewards;
  final Function onTap;
  final Function onUserTap;
  final GQLFeedItem? item;
  final HiveUserData appData;
  final bool showVideo;
  final VoidCallback? onFavouriteRemoved;
  final bool isGridView;

  @override
  State<NewFeedListItem> createState() => _NewFeedListItemState();
}

class _NewFeedListItemState extends State<NewFeedListItem>
    with AutomaticKeepAliveClientMixin {
  BetterPlayerController? _betterPlayerController;
  late final VideoSettingProvider videoSettingProvider;
  HomeFeedVideoController homeFeedVideoController = HomeFeedVideoController();
  final VideoFavoriteProvider favoriteProvider = VideoFavoriteProvider();

  @override
  void initState() {
    videoSettingProvider = context.read<VideoSettingProvider>();
    if (widget.showVideo) {
      _initVideo();
    }
    super.initState();
  }

  @override
  void dispose() {
    homeFeedVideoController.dispose();
    if (_betterPlayerController != null) {
      _betterPlayerController!.videoPlayerController!
          .removeListener(videoPlayerListener);
      _betterPlayerController!.removeEventsListener(videoEventListener);
      _betterPlayerController!.videoPlayerController?.dispose();
      _betterPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewFeedListItem oldWidget) {
    if (widget.showVideo &&
        _betterPlayerController == null &&
        !homeFeedVideoController.isUserOnAnotherScreen) {
      _initVideo();
    } else if (oldWidget.showVideo && !widget.showVideo) {
      if (_betterPlayerController != null) {
        homeFeedVideoController.skippedToInitialDuartion = false;
        _betterPlayerController!.videoPlayerController!
            .removeListener(videoPlayerListener);
        _betterPlayerController!.removeEventsListener(videoEventListener);
        homeFeedVideoController.reset();
        _betterPlayerController!.videoPlayerController?.dispose();
        _betterPlayerController!.dispose();
        _betterPlayerController = null;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  void setupVideo(
    String url,
  ) {
    BetterPlayerConfiguration betterPlayerConfiguration =
        BetterPlayerConfiguration(
      routePageBuilder:
          (context, animation, secondaryAnimation, controllerProvider) =>
              PopScope(
        onPopInvoked: (didPop) {
          if (didPop) {
            homeFeedVideoController.didPopFullScreen(_betterPlayerController!);
          }
        },
        child: BetterPlayer(
          controller: _betterPlayerController!,
        ),
      ),
      fit: BoxFit.contain,
      autoPlay: true,
      fullScreenByDefault: false,
      controlsConfiguration: BetterPlayerControlsConfiguration(
          enablePip: false,
          enableFullscreen: defaultTargetPlatform == TargetPlatform.android,
          enableSkips: true,
          enableMute: true),
      autoDetectFullscreenAspectRatio: false,
      placeholder:
          !widget.item!.isVideo ? videoThumbnail() : const SizedBox.shrink(),
      deviceOrientationsOnFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp
      ],
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp
      ],
      autoDispose: false,
      expandToFill: true,
      allowedScreenSleep: false,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      (widget.item!.isVideo)
          ? Platform.isAndroid
              ? url.replaceAll("/manifest.m3u8", "/480p/index.m3u8")
              : url
          : widget.item!.playUrl!,
      videoFormat: widget.item!.isVideo
          ? BetterPlayerVideoFormat.hls
          : BetterPlayerVideoFormat.other,
    );
    setState(() {
      _betterPlayerController =
          BetterPlayerController(betterPlayerConfiguration);
    });
    _betterPlayerController!.setupDataSource(dataSource);
    homeFeedVideoController.changeControlsVisibility(
        _betterPlayerController!, false);
  }

  void _initVideo() async {
    if (widget.item!.isVideo) {
      var url = widget.item!.videoV2M3U8(widget.appData);
      try {
        var data = await http.get(Uri.parse(url));
        if (data.body.contains('failed to resolve /ipfs')) {
          debugPrint('Invalid url. let\'s update it ${url}');
          url = widget.item!.mobileEncodedVideoUrl();
        } else {
          debugPrint('Valid URL. lets not update it. - ${data.body}');
        }
      } catch (e) {
        debugPrint('Invalid url. let\'s update it ${url}');
        url = widget.item!.mobileEncodedVideoUrl();
      }
      setupVideo(url);
    } else {
      setupVideo(widget.item!.playUrl!);
    }
    if (videoSettingProvider.isMuted) {
      _betterPlayerController!.setVolume(0.0);
    }
    _betterPlayerController!.videoPlayerController!
        .addListener(videoPlayerListener);
    _betterPlayerController!.addEventsListener(videoEventListener);
  }

  void videoPlayerListener() {
    homeFeedVideoController.videoPlayerListener(
        _betterPlayerController, videoSettingProvider);
  }

  void videoEventListener(BetterPlayerEvent event) {
    homeFeedVideoController.videoEventListener(_betterPlayerController, event);
  }

  Widget videoThumbnail() {
    return Selector<SettingsProvider, String>(
        selector: (context, myType) => myType.resolution,
        builder: (context, value, child) {
          return ThumbnailWidget(
            image: Utilities.getProxyImage(value, widget.thumbUrl),
            height: !widget.isGridView ? 230 : null,
            width: double.infinity,
          );
        });
  }

  Widget listTile() {
    TextStyle titleStyle =
        TextStyle(color: Theme.of(context).primaryColorLight, fontSize: 13);
    Widget thumbnail = videoThumbnail();
    String timeInString =
        widget.createdAt != null ? "${timeago.format(widget.createdAt!)}" : "";
    return InkWell(
      onTap: () {
        widget.onTap();
        if (widget.item == null) {
          var viewModel = VideoDetailsViewModel(
            author: widget.author,
            permlink: widget.permlink,
          );
          var screen = VideoDetailsScreen(vm: viewModel);
          var route = MaterialPageRoute(builder: (context) => screen);
          Navigator.of(context).push(route);
        } else {
          _pushToVideoDetailScreen();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            widget.isGridView
                ? Expanded(
                    child: _videoStack(thumbnail),
                  )
                : _videoStack(thumbnail),
            SizedBox(
              height: widget.isGridView ? 75 : null,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 10.0, bottom: 5, left: 13, right: 13),
                child: Row(
                  crossAxisAlignment:
                      !widget.isGridView && isTitleOneLine(titleStyle)
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      child: ClipOval(
                        child: CachedImage(
                          imageHeight: 40,
                          imageWidth: 40,
                          loadingIndicatorSize: 25,
                          imageUrl: server.userOwnerThumb(widget.author),
                        ),
                      ),
                      onTap: () {
                        widget.onUserTap();
                        _pushToUserScreen();
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              Gap(10),
                              ReportPopUpMenu(
                                iconSize: 20,
                                type: Report.post,
                                author: widget.author,
                                permlink: widget.permlink,
                              )
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              child: Row(
                                children: [
                                  Text(
                                    '${widget.author}',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryColorLight
                                            .withOpacity(0.7),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onUserTap();
                                _pushToUserScreen();
                              },
                            ),
                            Expanded(
                                child: Text(
                              '  •  $timeInString',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .primaryColorLight
                                      .withOpacity(0.7),
                                  fontSize: 12),
                            )),
                            const SizedBox(
                              width: 15,
                            ),
                            UpvoteButton(
                              appData: widget.appData,
                              item: widget.item!,
                              votes: widget.votes,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 2.5, left: 15),
                              child: Icon(
                                Icons.comment,
                                size: 14,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 1.0,
                              ),
                              child: Text(
                                '  ${widget.comments}',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .primaryColorLight
                                        .withOpacity(0.7),
                                    fontSize: 12),
                              ),
                            ),
                            // Padding(
                            //   padding:
                            //       const EdgeInsets.only(left: 10, top: 2.0, right: 5),
                            //   child: SizedBox(
                            //     height: 15,
                            //     width: 25,
                            //     child: FavouriteWidget(
                            //         alignment: Alignment.topCenter,
                            //         disablePadding: true,
                            //         iconSize: 15,
                            //         isLiked: favoriteProvider
                            //             .isLikedVideoPresentLocally(widget.item!),
                            //         onAdd: () {
                            //           favoriteProvider
                            //               .storeLikedVideoLocally(widget.item!);
                            //         },
                            //         onRemove: () {
                            //           favoriteProvider.storeLikedVideoLocally(
                            //               widget.item!,
                            //               forceRemove: true);
                            //           if (widget.onFavouriteRemoved != null)
                            //             widget.onFavouriteRemoved!();
                            //         },
                            //         toastType: 'Video'),
                            //   ),
                            // )
                          ],
                        ),
                      ],
                    ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack _videoStack(Widget thumbnail) {
    return Stack(
      children: [
        widget.showVideo && _betterPlayerController != null
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  _videoPlayer(),
                  _thumbNailAndLoader(thumbnail),
                  _nextScreenGestureDetector(),
                  _videoSlider(),
                  _interactionTools()
                ],
              )
            : widget.isGridView
                ? Positioned.fill(child: thumbnail)
                : thumbnail,
        _timer(),
      ],
    );
  }

  bool isTitleOneLine(
    TextStyle titleStyle,
  ) {
    return Utilities.textLines(widget.title, titleStyle,
            MediaQuery.of(context).size.width * 0.78, 2) ==
        1;
  }

  Positioned _nextScreenGestureDetector() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          _pushToVideoDetailScreen();
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  void _pushToVideoDetailScreen() async {
    homeFeedVideoController.isUserOnAnotherScreen = true;
    context.pushNamed(Routes.videoDetailsView,
        extra: NewVideoDetailScreenNavigationParameter(
            betterPlayerController: _betterPlayerController,
            item: widget.item,
            onPop: onPopFromUserViewOrVideoDetailsView),
        pathParameters: {'author': widget.author, 'permlink': widget.permlink});
  }

  void _pushToUserScreen() async {
    context.pushNamed(Routes.userView,
        pathParameters: {'author': widget.author},
        extra: onPopFromUserViewOrVideoDetailsView);
  }

  void onPopFromUserViewOrVideoDetailsView() {
    homeFeedVideoController.isUserOnAnotherScreen = false;
    if (widget.showVideo &&
        _betterPlayerController == null &&
        !homeFeedVideoController.isUserOnAnotherScreen) {
      setState(() {
        _initVideo();
      });
    }
  }

  Positioned _timer() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: HomeFeedVideoTimer(totalDuration: widget.duration ?? 0),
    );
  }

  Positioned _interactionTools() {
    return Positioned(
      top: 5,
      right: 5,
      child: Column(
        children: [
          HomeFeedVideoFullScreenButton(
              appData: widget.appData,
              item: widget.item!,
              betterPlayerController: _betterPlayerController!),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: MuteUnmuteButton(
                betterPlayerController: _betterPlayerController!),
          ),
          PlayPauseButton(betterPlayerController: _betterPlayerController!)
        ],
      ),
    );
  }

  Positioned _videoSlider() {
    return Positioned(
      left: -3,
      right: -3,
      bottom: 0,
      child: HomeFeedVideoSlider(
        betterPlayerController: _betterPlayerController,
      ),
    );
  }

  Positioned _thumbNailAndLoader(Widget thumbnail) {
    return Positioned.fill(
      child: Selector<HomeFeedVideoController, bool>(
        selector: (_, myType) => myType.isInitialized,
        builder: (context, value, child) {
          return Visibility(visible: !value, child: child!);
        },
        child: Stack(
          children: [
            thumbnail,
            Positioned(
              bottom: 10,
              left: 10,
              child: SizedBox(
                height: 13,
                width: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Hero _videoPlayer() {
    return Hero(
      tag: '${widget.item?.author}/${widget.item?.permlink}',
      child: SizedBox(
        height: !widget.isGridView ? 230 : null,
        child: BetterPlayer(
          controller: _betterPlayerController!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
        value: homeFeedVideoController, child: listTile());
  }

  @override
  bool get wantKeepAlive => homeFeedVideoController.currentDuration != null;
}
