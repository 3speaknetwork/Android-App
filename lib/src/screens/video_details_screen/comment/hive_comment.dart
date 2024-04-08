import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/video_details_screen/comment/comment_action_menu.dart';
import 'package:acela/src/screens/video_details_screen/comment/controller/comment_controller.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/confirmation_dialog.dart';
import 'package:acela/src/widgets/user_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class CommentTile extends StatefulWidget {
  const CommentTile(
      {Key? key,
      required this.comment,
      required this.isPadded,
      required this.index,
      required this.currentUser,
      required this.searchKey,
      required this.itemScrollController})
      : super(key: key);

  final CommentItemModel comment;
  final bool isPadded;
  final int index;
  final String currentUser;
  final String searchKey;
  final ItemScrollController itemScrollController;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile>
    with AutomaticKeepAliveClientMixin {
  late int votes;
  late bool isUpvoted;
  bool animate = false;
  bool animated = false;
  Duration duration = Duration.zero;
  late bool isHidden;
  late Color color;

  @override
  void initState() {
    _initVoteStatus();
    _initAnimation();
    isHidden = (widget.comment.authorReputation ?? 0) < 0 ||
        (widget.comment.netRshares ?? 0) < 0;
    super.initState();
  }

  void _initAnimation() {
    if (!animated) {
      Duration difference = DateTime.now().difference(widget.comment.created);
      animate = difference.inSeconds < 5;
      if (animate) {
        color = Colors.grey.shade500;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted)
            setState(() {
              duration = Duration(seconds: 5);
              color = Colors.transparent;
              animated = true;
              animate = false;
            });
        });
      } else {
        color = Colors.transparent;
      }
    } else {
      color = Colors.transparent;
    }
  }

  void _callbackToAnimate() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (mounted)
        setState(() {
          duration = Duration.zero;
          color = Colors.grey.shade500;
        });
      await Future.delayed(Duration(milliseconds: 50));
      if (mounted)
        setState(() {
          duration = Duration(seconds: 5);
          color = Colors.transparent;
          animated = true;
          animate = false;
        });
    });
  }

  void _initVoteStatus() {
    votes = widget.comment.stats?.totalVotes ?? 0;
    isUpvoted = widget.comment.activeVotes
        .contains(CommentActiveVote(voter: widget.currentUser));
  }

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    _initVoteStatus();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var item = widget.comment;
    var author = item.author;
    var body = item.body;
    var timeInString = "${timeago.format(item.created)}";
    var depth = (widget.isPadded ? 50.0 : 0.2 * 25.0);
    var style = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    return Selector<CommentController, bool>(
      selector: (_, provider) => provider.commentHighlighterTrigger,
      builder: (context, value, child) {
        final controller = context.read<CommentController>();
        if (widget.index == controller.animateToCommentIndex && value) {
          _callbackToAnimate();
          controller.animateToCommentIndex = null;
          controller.commentHighlighterTrigger = false;
        }
        return child!;
      },
      child: InkWell(
        onTap: () {
          if (isHidden) {
            _showCommentUnMuteDialog();
          } else {
            if (!widget.comment.isLocallyAdded) {
              _showBottomSheet(item, onUpvote: () {
                context.read<CommentController>().onUpvote(
                    item, widget.index, widget.currentUser, widget.searchKey);
                setState(() {
                  votes++;
                  isUpvoted = true;
                });
              });
            }
          }
        },
        child: AnimatedContainer(
          duration: duration,
          color: color,
          onEnd: () => setState(() {
            duration = Duration.zero;
          }),
          padding: EdgeInsets.only(
              left: depth + 15,
              right: 15,
              bottom: 15,
              top: widget.isPadded ? 0 : 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserProfileImage(userName: item.author),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(author, style: style),
                        const SizedBox(
                          width: 12,
                        ),
                        Icon(
                          isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 15,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(votes.toString(), style: style),
                        const SizedBox(
                          width: 12,
                        ),
                        Icon(
                          Icons.schedule,
                          size: 15,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                            child: Text(
                          timeInString,
                          style: style,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),),
                        if (isHidden)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.visibility_off),
                          )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              if (!isHidden) _comment(body)
            ],
          ),
        ),
      ),
    );
  }

  Widget _comment(String text) {
    return MarkdownBody(
      data: Utilities.removeAllHtmlTags(text),
      shrinkWrap: true,
      onTapLink: (text, url, title) {
        launchUrl(Uri.parse(url ?? 'https://google.com'));
      },
    );
  }

  void _showBottomSheet(CommentItemModel item,
      {required VoidCallback onUpvote}) {
    FocusScope.of(context).unfocus();
    final controller = context.read<CommentController>();
    showModalBottomSheet(
      backgroundColor: const Color(0xFF1B1A1A),
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      context: context,
      builder: (context) => CommentActionMenu(
        depth: item.depth,
        onSubCommentAdded: (newComment) {
          controller.addSubLevelComment(
              newComment, widget.index, widget.searchKey);

          if (widget.searchKey.isNotEmpty &&
              controller.disPlayedItems.contains(newComment)) {
            _animteToAddedComment(controller.sort == Sort.newest
                ? 0
                : controller.disPlayedItems.length - 1);
          }
        },
        onUpVote: onUpvote,
        appData: context.read<HiveUserData>(),
        author: item.author,
        permlink: item.permlink,
      ),
    );
  }

  void _showCommentUnMuteDialog() {
    showDialog(
      barrierDismissible: true,
      useRootNavigator: true,
      context: context,
      builder: (context) {
        return ConfirmationDialog(
            title: "Muted comment",
            content: "Are you sure you want to see muted comment ?",
            onConfirm: () {
              if (mounted)
                setState(() {
                  isHidden = false;
                });
            });
      },
    );
  }

  void _animteToAddedComment(int index) {
    widget.itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic);
  }

  @override
  bool get wantKeepAlive => true;
}
