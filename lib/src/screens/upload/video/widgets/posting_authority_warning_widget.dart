import 'package:acela/src/screens/upload/posting_authority_guide_screen.dart';
import 'package:acela/src/screens/upload/video/controller/video_upload_controller.dart';
import 'package:acela/src/widgets/blink_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostingAuthorityWarningWidget extends StatelessWidget {
  const PostingAuthorityWarningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final videoUploadController = context.read<VideoUploadController>();
    final theme = Theme.of(context);
    return ValueListenableBuilder(
        valueListenable: videoUploadController.hasPostingAuthority,
        builder: (context, isGiven, child) {
          if (!videoUploadController.isDeviceEncoding || isGiven == true)
            return SizedBox.shrink();
          return Container(
            color: theme.scaffoldBackgroundColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                ),
                BlinkWidget(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return PostingAuthorityGuideScreen();
                      }));
                    },
                    title: Center(
                      child: Text(
                        "Posting authority not given to @threespeak",
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }
}
