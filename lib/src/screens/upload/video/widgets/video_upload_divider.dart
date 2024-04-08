import 'package:flutter/material.dart';

class VideoUploadDivider extends StatelessWidget {
  const VideoUploadDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).cardColor.withOpacity(0.7),
    );
  }
}
