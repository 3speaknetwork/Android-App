import 'package:acela/src/global_provider/image_resolution_provider.dart';
import 'package:acela/src/global_provider/video_setting_provider.dart';
import 'package:acela/src/models/navigation_models/new_video_detail_screen_navigation_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/video_details_screen/new_video_details/video_detail_favourite_provider.dart';
import 'package:acela/src/screens/video_details_screen/video_details_view_model.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:acela/src/widgets/upvote_button.dart';
import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewFeedListItem extends StatefulWidget {
  const NewFeedListItem(
      {super.key,
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
      this.appData,
      this.showVideo = false,
      this.onFavouriteRemoved,
      this.isGridView = false});

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
  final HiveUserData? appData;
  final bool showVideo;
  final VoidCallback? onFavouriteRemoved;
  final bool isGridView;

  @override
  State<NewFeedListItem> createState() => _NewFeedListItemState();
}

class _NewFeedListItemState extends State<NewFeedListItem> {
  late final VideoSettingProvider videoSettingProvider;
  final VideoFavoriteProvider favoriteProvider = VideoFavoriteProvider();

  @override
  void initState() {
    videoSettingProvider = context.read<VideoSettingProvider>();

    super.initState();
  }

  Widget videoThumbnail() {
    return Selector<SettingsProvider, String>(
        selector: (context, myType) => myType.resolution,
        builder: (context, value, child) {
          return CachedImage(
            imageUrl: Utilities.getProxyImage(value, widget.thumbUrl),
            imageWidth: double.infinity,
            isCached: false,
            fit: widget.isGridView ? BoxFit.cover : null,
            imageHeight: !widget.isGridView ? 230 : null,
          );
        });
  }

  Widget listTile() {
    TextStyle titleStyle =
        TextStyle(color: Theme.of(context).primaryColorLight, fontSize: 13);
    Widget thumbnail = videoThumbnail();
    String timeInString =
        widget.createdAt != null ? timeago.format(widget.createdAt!) : "";
    return InkWell(
      onTap: () {
        widget.onTap();
        if (widget.item == null || widget.appData == null) {
          var viewModel = VideoDetailsViewModel(
            author: widget.author,
            permlink: widget.permlink,
          );
          // var screen = VideoDetailsScreen(vm: viewModel);
          // var route = MaterialPageRoute(builder: (context) => screen);
          // Navigator.of(context).push(route);
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
                    child: thumbnail,
                  )
                : thumbnail,
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
                    UserProfileimage(
                        verticalPadding: 0,
                        onTap: () {
                          widget.onUserTap();
                          _pushToUserScreen();
                        },
                        url: widget.author),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0),
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              child: Row(
                                children: [
                                  Text(
                                    widget.author,
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
                              appData: widget.appData!,
                              item: widget.item!,
                              votes: widget.votes,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 2.5, left: 15),
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

  Widget _videoStack(Widget thumbnail) {
    return thumbnail;
  }

  bool isTitleOneLine(
    TextStyle titleStyle,
  ) {
    return Utilities.textLines(widget.title, titleStyle,
            MediaQuery.of(context).size.width * 0.78, 2) ==
        1;
  }

  void _pushToVideoDetailScreen() async {
    context.pushNamed(Routes.videoDetailsView,
        extra: NewVideoDetailScreenNavigationParameter(
            item: widget.item, onPop: () {}),
        pathParameters: {'author': widget.author, 'permlink': widget.permlink});
  }

  void _pushToUserScreen() async {
    context.pushNamed(
      Routes.userView,
      pathParameters: {'author': widget.author},
    );
  }

  @override
  Widget build(BuildContext context) {
    return listTile();
  }
}
