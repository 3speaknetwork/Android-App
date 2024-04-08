import 'dart:convert';
import 'dart:developer';
import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/screens/podcast/widgets/favourite.dart';
import 'package:acela/src/screens/video_details_screen/comment/hive_comment_dialog.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/models/hive_post_info/hive_post_info.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/video_details_screen/hive_upvote_dialog.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details_info.dart';
import 'package:acela/src/screens/video_details_screen/comment/video_details_comments.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:better_player/better_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

class StoryPlayer extends StatefulWidget {
  const StoryPlayer({
    Key? key,
    required this.didFinish,
    required this.item,
    required this.data,
    this.onRemoveFavouriteCallback,
  }) : super(key: key);
  final GQLFeedItem item;
  final Function didFinish;
  final HiveUserData data;
  final VoidCallback? onRemoveFavouriteCallback;

  @override
  _StoryPlayerState createState() => _StoryPlayerState();
}

class _StoryPlayerState extends State<StoryPlayer> {
  late BetterPlayerController _betterPlayerController;
  HivePostInfoPostResultBody? postInfo;
  bool controlsVisible = false;

  var aspectRatio = 0.0; // 0.5625
  double? height;
  double? width;

  @override
  void dispose() {
    super.dispose();
    _betterPlayerController.removeEventsListener(controlsVisibilityListenener);
    _betterPlayerController.videoPlayerController!
        .removeListener(_videoPlayerListener);
    _betterPlayerController.dispose();
  }

  @override
  void initState() {
    super.initState();
    updateRatio();
    loadHiveInfo();
  }

  void loadHiveInfo() async {
    setState(() {
      postInfo = null;
    });
    var data = await fetchHiveInfoForThisVideo(widget.data.rpc);
    setState(() {
      postInfo = data;
    });
  }

  Future<HivePostInfoPostResultBody> fetchHiveInfoForThisVideo(
      String hiveApiUrl) async {
    var request = http.Request('POST', Uri.parse('https://$hiveApiUrl'));
    request.body = json.encode({
      "id": 1,
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {
        "author": widget.item.author?.username ?? 'sagarkothari88',
        "permlink": widget.item.permlink ?? 'ctbtwcxbbd',
        "observer": ""
      }
    });
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var result = HivePostInfo.fromJsonString(string)
          .result
          .resultData
          .where((element) =>
              element.permlink == (widget.item.permlink ?? 'ctbtwcxbbd'))
          .first;
      return result;
    } else {
      print(response.reasonPhrase);
      throw response.reasonPhrase ?? 'Can not load payout info';
    }
  }

  void updateRatio() async {
    var ratio = await Communicator().getAspectRatio(widget.item.hlsUrl);
    setState(() {
      aspectRatio = ratio.width / ratio.height;
      setupPlayer();
    });
  }

  void setupPlayer() {
    BetterPlayerConfiguration config = BetterPlayerConfiguration(
      aspectRatio: aspectRatio,
      fit: BoxFit.fitHeight,
      autoPlay: true,
      fullScreenByDefault: false,
      deviceOrientationsOnFullScreen: [
        DeviceOrientation.portraitUp,
      ],
      autoDispose: true,
      expandToFill: true,
      controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: true,
          showControlsOnInitialize: false,
          enableFullscreen: false,
          enableMute: true),
      showPlaceholderUntilPlay: true,
      allowedScreenSleep: false,
      eventListener: (event) {
        log('type - ${event.betterPlayerEventType.toString()}');
        if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
          widget.didFinish();
        }
      },
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.item.videoV2M3U8(widget.data),
      videoFormat: BetterPlayerVideoFormat.hls,
    );
    setState(() {
      _betterPlayerController = BetterPlayerController(config);
      _betterPlayerController.setupDataSource(dataSource);
    });
    final videoSettingProvider = context.read<VideoSettingProvider>();
    if (videoSettingProvider.isMuted) {
      _betterPlayerController.setVolume(0.0);
    }
    _betterPlayerController.videoPlayerController!
        .addListener(_videoPlayerListener);
    _betterPlayerController.addEventsListener(controlsVisibilityListenener);
  }

  void _videoPlayerListener() {
    final videoSettingProvider = context.read<VideoSettingProvider>();
    if (_betterPlayerController.videoPlayerController != null &&
        _betterPlayerController.videoPlayerController!.value.initialized) {
      if (_betterPlayerController.videoPlayerController!.value.volume == 0.0 &&
          !videoSettingProvider.isMuted) {
        videoSettingProvider.changeMuteStatus(true);
      } else if (_betterPlayerController.videoPlayerController!.value.volume !=
              0.0 &&
          videoSettingProvider.isMuted) {
        videoSettingProvider.changeMuteStatus(false);
      }
    }
  }

  void controlsVisibilityListenener(BetterPlayerEvent p0) {
    if (p0.betterPlayerEventType == BetterPlayerEventType.controlsVisible) {
      if (!controlsVisible) {
        setState(() {
          controlsVisible = true;
        });
      }
    } else {
      if (p0.betterPlayerEventType == BetterPlayerEventType.controlsHiddenEnd) {
        if (controlsVisible) {
          setState(() {
            controlsVisible = false;
          });
        }
      }
    }
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void seeCommentsPressed() {
    _betterPlayerController.pause();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return VideoDetailsComments(
            appData: widget.data,
            item: widget.item,
            author: widget.item.author?.username ?? 'sagarkothari88',
            permlink: widget.item.permlink ?? 'ctbtwcxbbd',
            rpc: widget.data.rpc,
          );
        },
      ),
    );
  }

  void upvotePressed() {
    if (postInfo == null) return;
    if (widget.data.username == null) {
      _betterPlayerController.pause();
      showAdaptiveActionSheet(
        context: context,
        title: const Text('You are not logged in. Please log in to upvote.'),
        androidBorderRadius: 30,
        actions: [
          BottomSheetAction(
              title: Text('Log in'),
              leading: Icon(Icons.login),
              onPressed: (c) {
                Navigator.of(c).pop();
                var screen = HiveAuthLoginScreen(appData: widget.data);
                var route = MaterialPageRoute(builder: (c) => screen);
                Navigator.of(c).push(route);
              }),
        ],
        cancelAction: CancelAction(title: const Text('Cancel')),
      );
      return;
    }
    if (postInfo!.activeVotes
            .map((e) => e.voter)
            .contains(widget.data.username ?? 'sagarkothari88') ==
        true) {
      showError('You have already voted for this 3Shorts');
    }
    _betterPlayerController.pause();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: HiveUpvoteDialog(
            author: widget.item.author?.username ?? 'sagarkothari88',
            permlink: widget.item.permlink ?? 'ctbtwcxbbd',
            username: widget.data.username ?? "",
            hasKey: widget.data.keychainData?.hasId ?? "",
            hasAuthKey: widget.data.keychainData?.hasAuthKey ?? "",
            accessToken: widget.data.accessToken,
            postingAuthority: widget.data.postingAuthority,
            activeVotes: postInfo!.activeVotes,
            onClose: () {},
            onDone: () {
              setState(() {
                postInfo = postInfo!.copyWith(activeVotes: [
                ...postInfo!.activeVotes,
                ActiveVotesItem(voter: widget.data.username!)
              ]);
              });
            },
          ),
        );
      },
    );
  }

  List<Widget> _fabButtonsOnRight() {
    final VideoFavoriteProvider provider = VideoFavoriteProvider();
    return [
      FavouriteWidget(
          toastType: "Video Short",
          iconColor: Colors.blue,
          isLiked:
              provider.isLikedVideoPresentLocally(widget.item, isShorts: true),
          onAdd: () {
            provider.storeLikedVideoLocally(widget.item, isShorts: true);
          },
          onRemove: () {
            provider.storeLikedVideoLocally(widget.item, isShorts: true);
            if (widget.onRemoveFavouriteCallback != null)
              widget.onRemoveFavouriteCallback!();
          }),
      IconButton(
        icon: Icon(Icons.share, color: Colors.blue),
        onPressed: () {
          _betterPlayerController.pause();
          Share.share(
              'https://3speak.tv/watch?v=${widget.item.author?.username ?? ''}/${widget.item.permlink ?? ''}');
        },
      ),
      SizedBox(height: 10),
      IconButton(
        icon: Icon(Icons.info, color: Colors.blue),
        onPressed: () {
          _betterPlayerController.pause();
          var screen = NewVideoDetailsInfo(
            appData: widget.data,
            item: widget.item,
          );
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(context).push(route);
        },
      ),
      SizedBox(height: 10),
      IconButton(
        icon: Icon(Icons.comment, color: Colors.blue),
        onPressed: () {
          seeCommentsPressed();
        },
      ),
      SizedBox(height: 10),
      IconButton(
        onPressed: () {
          if (postInfo != null) {
            upvotePressed();
          }
        },
        icon: Icon(isVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
            color: Colors.blue),
      ),
      SizedBox(height: 10),
      IconButton(
        icon: Icon(Icons.fullscreen, color: Colors.blue),
        onPressed: () async {
          _betterPlayerController.pause();
          var position =
              await _betterPlayerController.videoPlayerController?.position;
          debugPrint('position is $position');
          var seconds = position?.inSeconds;
          if (seconds == null) return;
          const platform = MethodChannel('com.example.acela/auth');
          await platform.invokeMethod('playFullscreen', {
            'url': widget.item.videoV2M3U8(widget.data),
            'seconds': seconds,
          });
        },
      ),
      SizedBox(height: 10),
    ];
  }

  bool get isVoted {
    if (widget.data.username == null) {
      return false;
    } else if (postInfo != null &&
        postInfo!.activeVotes
            .contains(ActiveVotesItem(voter: widget.data.username!))) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          aspectRatio == 0.0
              ? Center(child: CircularProgressIndicator())
              : BetterPlayer(
                  controller: _betterPlayerController,
                ),
          Visibility(
            visible: !controlsVisible,
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: Row(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              height: 40,
                              width: 40,
                              imageUrl: server.userOwnerThumb(
                                  widget.item.author?.username ??
                                      'sagarkothari88'),
                              progressIndicatorBuilder:
                                  (context, url, progress) => Container(
                                padding: EdgeInsets.all(8),
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.blue)),
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.blue)),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.author!.username!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${timeago.format(widget.item.createdAt!)}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      onPressed: () {
                        context.pushNamed(Routes.userView, pathParameters: {
                          'author':
                              widget.item.author?.username ?? 'sagarkothari88'
                        });
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 35,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _fabButtonsOnRight(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
