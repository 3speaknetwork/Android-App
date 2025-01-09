import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/report/widgets/report_post_dialog.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportPopUpMenu extends StatelessWidget {
  const ReportPopUpMenu({
    super.key,
    required this.type,
    required this.author,
    this.permlink,
    this.iconSize
  });

  final Report type;
  final String author;
  final String? permlink;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'option1',
          child: Text(
            'Report',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
      onSelected: (String value) {
        var userData = context.read<HiveUserData>();
        switch (value) {
          case 'option1':
            if (userData.username == null) {
              showAdaptiveActionSheet(
                context: context,
                title: const Text('You are not logged in. Please log in.'),
                androidBorderRadius: 30,
                actions: [
                  BottomSheetAction(
                      title: Text('Log in'),
                      leading: Icon(Icons.login),
                      onPressed: (c) {
                        Navigator.of(c).pop();
                        var screen = HiveAuthLoginScreen(appData: userData);
                        var route = MaterialPageRoute(builder: (c) => screen);
                        Navigator.of(c).push(route);
                      }),
                ],
                cancelAction: CancelAction(title: const Text('Cancel')),
              );
            } else {
              showDialog(
                context: context,
                builder: (_) => ReportPostDialog(
                  reportType: type,
                  rootContext: context,
                  author: author,
                  permlink: permlink,
                  onSuccessRemove: (reportType) {
                    // if (reportType == Report.reply) {
                    //   context.read<InboxController>().removeReplies(
                    //       widget.item.author, widget.item.permlink);
                    // } else {
                    //   context
                    //       .read<InboxController>()
                    //       .removeAuthor(widget.item.author);
                    // }
                  },
                ),
              );
            }
            break;
        }
      },
      child:  Icon(
        Icons.more_vert,
        size: iconSize,
      ),
    );
  }
}
