import 'dart:io';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/upload/video/video_upload_screen.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ThumbnailPickerView extends StatefulWidget {
  const ThumbnailPickerView(
      {super.key,
      required this.appData,
      required this.isCamera,
      required this.isDeviceEncode});

  final HiveUserData appData;
  final bool isCamera;
  final bool isDeviceEncode;
  @override
  State<ThumbnailPickerView> createState() => _ThumbnailPickerViewState();
}

class _ThumbnailPickerViewState extends State<ThumbnailPickerView> {
  File? file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Pick Thumbnail"),
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton.extended(
          label: Text("Next"),
          onPressed: () {
            var screen = VideoUploadScreen(
              isCamera: widget.isCamera,
              appData: widget.appData,
              isDeviceEncode: widget.isDeviceEncode,
              thumbnailFile: file,
            );
            var route = MaterialPageRoute(builder: (c) => screen);
            Navigator.of(context).pop();
            Navigator.of(context).push(route);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: kScreenPadding,
          child: Column(
            children: [
              InkWell(
                onTap: _onTap,
                child: Container(
                    color: theme.cardColor.withOpacity(0.5),
                    width: double.infinity,
                    height: 160,
                    child: file != null ? Image.file(file!) : null),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload),
                    const SizedBox(
                      width: 7,
                    ),
                    Text(
                      "Tap here to set thumbnail",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        if (mounted) {
          setState(() {
            this.file = File(file.path);
          });
        }
      }
    } catch (e) {}
  }
}
