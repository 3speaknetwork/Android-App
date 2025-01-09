import 'dart:convert';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/global_provider/image_resolution_provider.dart';
import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/models/hive_post_info/hive_post_info.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/feed_item_grid_view.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/new_feed_list_item.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/trending_tags/trending_tag_videos.dart';
import 'package:acela/src/screens/video_details_screen/comment/video_details_comments.dart';
import 'package:acela/src/screens/video_details_screen/hive_upvote_dialog.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details_info.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/box_loading/video_detail_feed_loader.dart';
import 'package:acela/src/widgets/box_loading/video_feed_loader.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:auth/core/widgets/user/user_profile_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NewVideoDetailsScreen extends StatefulWidget {
  const NewVideoDetailsScreen({
    super.key,
    this.item,
    required this.author,
    required this.permlink,
  });

  final GQLFeedItem? item;
  final String author;
  final String permlink;

  @override
  State<NewVideoDetailsScreen> createState() => _NewVideoDetailsScreenState();
}

class _NewVideoDetailsScreenState extends State<NewVideoDetailsScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  late GQLFeedItem item;
  bool isLoadingVideo = true;
  HivePostInfoPostResultBody? postInfo;
  var selectedChip = 0;
  late final VideoSettingProvider videoSettingProvider;
  late HiveUserData appData;
  List<GQLFeedItem> suggestions = [];
  bool isSuggestionsLoading = true;

  @override
  void initState() {
    appData = context.read<HiveUserData>();
    videoSettingProvider = context.read<VideoSettingProvider>();
    super.initState();
    WakelockPlus.enable();
    loadDataAndVideo();
    loadHiveInfo();
    loadSuggestions();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void loadSuggestions() async {
    var items = await GQLCommunicator().getRelated(
      widget.author,
      widget.permlink,
      appData.language,
    );
    setState(() {
      suggestions = items;
      isSuggestionsLoading = false;
    });
  }

  void loadHiveInfo() async {
    setState(() {
      postInfo = null;
    });
    var data = await fetchHiveInfoForThisVideo(appData.rpc);
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
        "author": widget.author,
        "permlink": widget.permlink,
        "observer": ""
      }
    });
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var result = HivePostInfo.fromJsonString(string)
          .result
          .resultData
          .where((element) => element.permlink == (widget.permlink))
          .first;
      return result;
    } else {
      print(response.reasonPhrase);
      throw response.reasonPhrase ?? 'Can not load payout info';
    }
  }

  Widget videoThumbnail() {
    return Selector<SettingsProvider, String>(
        selector: (context, myType) => myType.resolution,
        builder: (context, value, child) {
          return CachedImage(
            imageUrl: Utilities.getProxyImage(
                value, (item.spkvideo?.thumbnailUrl ?? '')),
            imageHeight: 230,
            imageWidth: double.infinity,
          );
        });
  }

  void setupVideo(
    String url,
  ) async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      autoInitialize: true
      // aspectRatio: 16 / 9,
      // errorBuilder: (context, errorMessage) {
      //   return Center(
      //     child: Text(
      //       'An error occurred: $errorMessage',
      //       style: TextStyle(color: Colors.red),
      //     ),
      // );
      // },
    );
    setState(() {});
  }

  void loadDataAndVideo() async {
    if (widget.item != null) {
      item = widget.item!;
      isLoadingVideo = false;
    } else {
      var data = await GQLCommunicator()
          .getVideoDetails(widget.author, widget.permlink);
      setState(() {
        item = data;
        isLoadingVideo = false;
      });
    }

    if (item.isVideo) {
      setupVideo(
        item.videoV2M3U8(appData),
      );
    } else {
      setupVideo(item.playUrl!);
    }
  }

  Widget _videoPlayerStack(double screenHeight, bool isGridView) {
    return SliverToBoxAdapter(
      child: Hero(
        tag: '${item.author}/${item.permlink}',
        child: SizedBox(
          height: isGridView ? screenHeight * 0.4 : 230,
          child: _chewieController != null &&
                  _chewieController!.videoPlayerController.value.isInitialized
              ? Chewie(
                  controller: _chewieController!,
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _userInfo() {
    String timeInString =
        item.createdAt != null ? timeago.format(item.createdAt!) : "";
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 5),
        child: ListTile(
          contentPadding: const EdgeInsets.only(top: 0, left: 15, right: 15),
          dense: true,
          splashColor: Colors.transparent,
          onTap: () {
            context.pushNamed(Routes.userView, pathParameters: {
              'author': item.author?.username ?? "sagarkothari88"
            });
          },
          leading:
              UserProfileimage(url: item.author?.username ?? 'sagarkothari88'),
          title: Text(
            item.title ?? 'No title',
            style: TextStyle(
                color: Theme.of(context).primaryColorLight,
                fontWeight: FontWeight.bold,
                fontSize: 17),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  item.author?.username ?? "sagarkothari88",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).primaryColorLight),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                timeInString,
                style: TextStyle(
                    color: Theme.of(context).primaryColorLight.withOpacity(0.7),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showVoters() {
    List<String> voters = [];
    bool currentUserPresentInVoters = false;
    if (postInfo != null) {
      if (appData.username != null) {
        int userNameInVotesIndex = postInfo!.activeVotes
            .indexWhere((element) => element.voter == appData.username);
        if (userNameInVotesIndex != -1) {
          currentUserPresentInVoters = true;
          voters.add(appData.username!);
          for (int i = 0; i < postInfo!.activeVotes.length; i++) {
            if (i != userNameInVotesIndex) {
              voters.add(postInfo!.activeVotes[i].voter);
            }
          }
        } else {
          for (var element in postInfo!.activeVotes) {
            voters.add(element.voter);
          }
        }
      } else {
        for (var element in postInfo!.activeVotes) {
          voters.add(element.voter);
        }
      }
    }
    for (var element in postInfo!.activeVotes) {
      print(element.voter);
    }
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            AppBar(
              title: Text("Voters (${voters.length})"),
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      upvotePressed();
                    },
                    icon: Icon(
                      Icons.thumb_up_sharp,
                      color: isUserVoted() ? Colors.blue : Colors.grey,
                    ))
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                itemCount: voters.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    minLeadingWidth: 0,
                    dense: true,
                    minVerticalPadding: 0,
                    leading: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            server.userOwnerThumb(voters[index]),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      voters[index],
                      style: TextStyle(
                          color: index == 0 && currentUserPresentInVoters
                              ? Colors.blue
                              : null),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void upvotePressed() {
    if (postInfo == null) return;
    if (appData.username == null) {
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
                var screen = HiveAuthLoginScreen(appData: appData);
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
            .contains(appData.username ?? 'sagarkothari88') ==
        true) {
      showError('You have already voted for this video');
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return HiveUpvoteDialog(
          author: item.author?.username ?? 'sagarkothari88',
          permlink: item.permlink ?? 'ctbtwcxbbd',
          username: appData.username ?? "",
          accessToken: appData.accessToken,
          postingAuthority: appData.postingAuthority,
          hasKey: appData.keychainData?.hasId ?? "",
          hasAuthKey: appData.keychainData?.hasAuthKey ?? "",
          activeVotes: postInfo!.activeVotes,
          onClose: () {},
          onDone: () {
            loadHiveInfo();
          },
        );
      },
    );
  }

  void infoPressed(double screenWidth) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewVideoDetailsInfo(
            appData: appData,
            item: item,
          ),
        ));
  }

  void seeCommentsPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return VideoDetailsComments(
            author: item.author?.username ?? 'sagarkothari88',
            permlink: item.permlink ?? 'ctbtwcxbbd',
            rpc: appData.rpc,
            appData: appData,
            item: item,
          );
        },
      ),
    );
  }

  Widget _actionBar(double width) {
    final VideoFavoriteProvider provider = VideoFavoriteProvider();
    Color color = Theme.of(context).primaryColorLight;
    String votes = "${item.stats?.numVotes ?? 0}";
    String comments = "${item.stats?.numComments ?? 0}";
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                infoPressed(width);
              },
              icon: Icon(Icons.info, color: color),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    seeCommentsPressed();
                  },
                  icon: Icon(Icons.comment, color: color),
                ),
                Text(comments,
                    style: TextStyle(
                        color: Theme.of(context)
                            .primaryColorLight
                            .withOpacity(0.7),
                        fontSize: 13))
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (postInfo != null) {
                      showVoters();
                    }
                  },
                  icon: Icon(
                      isUserVoted() ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: color),
                ),
                Text(votes,
                    style: TextStyle(
                        color: Theme.of(context)
                            .primaryColorLight
                            .withOpacity(0.7),
                        fontSize: 13))
              ],
            ),
            IconButton(
              onPressed: () {
                Share.share(
                    'https://3speak.tv/watch?v=${item.author?.username ?? 'sagarkothari88'}/${item.permlink}');
              },
              icon: Icon(Icons.share, color: color),
            ),
          ],
        ),
      ),
    );
  }

  bool isUserVoted() {
    if (appData.username != null) {
      if (postInfo != null && postInfo!.activeVotes.isNotEmpty) {
        int index = postInfo!.activeVotes
            .indexWhere((element) => element.voter == appData.username);
        if (index != -1) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _chipList() {
    List<String> tags = item.tags ?? ['threespeak', 'video', 'threeshorts'];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15.0, top: 5),
        child: SizedBox(
          height: 33,
          child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
              itemCount: tags.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(18),
                    ),
                    onTap: () {
                      var screen = TrendingTagVideos(tag: tags[index]);
                      var route = MaterialPageRoute(builder: (c) => screen);
                      Navigator.of(context).push(route);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context)
                                .primaryColorLight
                                .withOpacity(0.3)),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        tags[index],
                        style: TextStyle(
                            color: Theme.of(context).primaryColorLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final isGridView = MediaQuery.of(context).size.shortestSide > 600;
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          !isLoadingVideo
              ? _videoPlayerStack(height, isGridView)
              : sliverSizedBox(),
          !isLoadingVideo ? _userInfo() : sliverSizedBox(),
          !isLoadingVideo ? _actionBar(width) : sliverSizedBox(),
          !isLoadingVideo ? _chipList() : sliverSizedBox(),
          SliverVisibility(
            visible: isLoadingVideo,
            sliver: SliverToBoxAdapter(
              child: VideoDetailFeedLoader(isGridView: isGridView),
            ),
          ),
          isSuggestionsLoading
              ? VideoFeedLoader(
                  isSliver: true,
                  isGridView: isGridView,
                )
              : isGridView
                  ? _sliverGridView()
                  : _sliverListView(),
        ],
      )),
    );
  }

  Widget sliverSizedBox() {
    return const SliverToBoxAdapter(
      child: SizedBox.shrink(),
    );
  }

  Widget _sliverGridView() {
    return FeedItemGridWidget(items: suggestions, appData: appData);
  }

  SliverList _sliverListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          var item = suggestions[index];
          return NewFeedListItem(
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
            appData: appData,
          );
        },
        childCount: suggestions.length,
      ),
    );
  }
}
