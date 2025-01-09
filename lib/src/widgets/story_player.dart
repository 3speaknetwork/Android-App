import 'dart:convert';

import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/models/hive_post_info/hive_post_info.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/video_details_screen/comment/video_details_comments.dart';
import 'package:acela/src/screens/video_details_screen/hive_upvote_dialog.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details_info.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:acela/src/widgets/favourite.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:auth/auth.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

class StoryPlayer extends StatefulWidget {
  const StoryPlayer({
    super.key,
    required this.didFinish,
    required this.item,
    required this.data,
    required this.isCurrentTab,
    this.onRemoveFavouriteCallback,
  });
  final GQLFeedItem item;
  final Function didFinish;
  final HiveUserData data;
  final bool isCurrentTab;
  final VoidCallback? onRemoveFavouriteCallback;

  @override
  _StoryPlayerState createState() => _StoryPlayerState();
}

class _StoryPlayerState extends State<StoryPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  HivePostInfoPostResultBody? postInfo;
  bool controlsVisible = false;
  late final VideoSettingProvider videoSettingProvider;

  var aspectRatio = 0.0; // 0.5625
  double? height;
  double? width;

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    videoSettingProvider = context.read<VideoSettingProvider>();
    updateRatio();
    loadHiveInfo();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StoryPlayer oldWidget) {
    if (widget.isCurrentTab) {
      _videoPlayerController.play();
    } else {
      _videoPlayerController.pause();
    }
    super.didUpdateWidget(oldWidget);
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
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.hlsUrl),
    );
    await _videoPlayerController.initialize();
    var ratio = await Communicator().getAspectRatio(widget.item.hlsUrl);

    setState(() {
      aspectRatio = ratio.width / ratio.height;
      setupPlayer();
    });
  }

  void setupPlayer() {
    _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        autoInitialize: true,
        aspectRatio: aspectRatio,
        showControlsOnInitialize: false);
    if (!widget.isCurrentTab) {
      _videoPlayerController.pause();
    } else {
      _videoPlayerController.play();
    }
    if(mounted){
      setState(() {});
    }
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void seeCommentsPressed() {
    _videoPlayerController.pause();
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
      _videoPlayerController.pause();
      showAdaptiveActionSheet(
        context: context,
        title: const Text('You are not logged in. Please log in to upvote.'),
        androidBorderRadius: 30,
        actions: [
          BottomSheetAction(
              title: const Text('Log in'),
              leading: const Icon(Icons.login),
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
    _videoPlayerController.pause();
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
            if (widget.onRemoveFavouriteCallback != null) {
              widget.onRemoveFavouriteCallback!();
            }
          }),
      IconButton(
        icon: const Icon(Icons.share, color: Colors.blue),
        onPressed: () {
          _videoPlayerController.pause();
          Share.share(
              'https://3speak.tv/watch?v=${widget.item.author?.username ?? ''}/${widget.item.permlink ?? ''}');
        },
      ),
      const SizedBox(height: 10),
      IconButton(
        icon: const Icon(Icons.info, color: Colors.blue),
        onPressed: () {
          _videoPlayerController.pause();
          var screen = NewVideoDetailsInfo(
            appData: widget.data,
            item: widget.item,
          );
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(context).push(route);
        },
      ),
      const SizedBox(height: 10),
      IconButton(
        icon: const Icon(Icons.comment, color: Colors.blue),
        onPressed: () {
          seeCommentsPressed();
        },
      ),
      const SizedBox(height: 10),
      IconButton(
        onPressed: () {
          if (postInfo != null) {
            upvotePressed();
          }
        },
        icon: Icon(isVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
            color: Colors.blue),
      ),
      const SizedBox(height: 10),
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
          aspectRatio == 0.0 ||
                  _chewieController == null ||
                  !_chewieController!.videoPlayerController.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  child: Chewie(
                    controller: _chewieController!,
                  ),
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
                          UserProfileimage(
                              url: widget.item.author?.username ??
                                  'sagarkothari88'),
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
                                  timeago.format(widget.item.createdAt!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
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
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: _fabButtonsOnRight(),
                      ),
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
