import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/video_details_screen/comment/hive_comment_dialog.dart';
import 'package:acela/src/screens/video_details_screen/hive_upvote_dialog.dart';
import 'package:acela/src/widgets/bottom_sheet_outline.dart';
import 'package:acela/src/widgets/menu_circle_action_button.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';

class CommentActionMenu extends StatelessWidget {
  const CommentActionMenu(
      {Key? key,
      required this.appData,
      required this.author,
      required this.permlink,
      required this.onUpVote,
      required this.depth,
      required this.onSubCommentAdded})
      : super(key: key);

  final HiveUserData appData;
  final String author;
  final String permlink;
  final int depth;
  final VoidCallback onUpVote;
  final Function(CommentItemModel) onSubCommentAdded;

  @override
  Widget build(BuildContext context) {
    return BottomSheetOutline(
      children: [
        MenuCircleActionButton(
          onTap: () => onUpvoteTap(context),
          icon: Icons.thumb_up_sharp,
          text: "Upvote",
        ),
        MenuCircleActionButton(
          onTap: () => onReplyTap(context),
          icon: Icons.reply,
          text: "Reply",
        ),
        MenuCircleActionButton(
          onTap: () {
            Navigator.pop(context);
          },
          icon: Icons.close,
          text: "Cancel",
          backgroundColor: Colors.red,
        ),
      ],
    );
  }

  void onUpvoteTap(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        child: HiveUpvoteDialog(
          author: author,
          permlink: permlink,
          username: appData.username ?? "",
          accessToken: appData.accessToken,
          postingAuthority: appData.postingAuthority,
          hasKey: appData.keychainData?.hasId ?? "",
          hasAuthKey: appData.keychainData?.hasAuthKey ?? "",
          activeVotes: [],
          onClose: () {},
          onDone: onUpVote,
        ),
      ),
    );
  }

  void onReplyTap(BuildContext context) {
    Navigator.of(context).pop();
    if (appData.username == null) {
      showAdaptiveActionSheet(
        context: context,
        title: const Text('You are not logged in. Please log in to comment.'),
        androidBorderRadius: 30,
        actions: [
          BottomSheetAction(
              title: Text('Log in'),
              leading: Icon(Icons.login),
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
    var screen = HiveCommentDialog(
      author: author,
      permlink: permlink,
      depth:depth ,
      username: appData.username ?? "",
      hasKey: appData.keychainData?.hasId ?? "",
      hasAuthKey: appData.keychainData?.hasAuthKey ?? "",
      onClose: () {},
      onDone: (newComment) async {
        if(newComment!=null){
          onSubCommentAdded(newComment);
        }
      },
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => screen));
  }
}
