import 'dart:io';

import 'package:acela/src/extensions/ui.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/video_encoder_switch.dart';
import 'package:acela/src/screens/upload/video/thumbnail_picker_view.dart';
import 'package:acela/src/screens/upload/video/video_editor/video_edit_screen.dart';
import 'package:acela/src/screens/upload/video/video_editor/video_result_player.dart';
import 'package:acela/src/screens/upload/video/video_upload_screen.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  final ValueNotifier<bool> isDeviceEncode = ValueNotifier(true);

  XFile? file;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          label: Text("Next"), onPressed: () => onNext(context)),
      appBar: AppBar(
        title: Text("Pick your video"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kScreenVerticalPadding,
          child: Column(
            children: [
              if (file != null)
                Padding(
                  padding: kScreenHorizontalPadding,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        _videoHeader(context),
                        Container(
                            color: Colors.grey.shade900.withOpacity(0.2),
                            width: double.infinity,
                            height: 300,
                            child: VideoResultPlayer(video: File(file!.path))),
                      ],
                    ),
                  ),
                ),
              ListTile(
                leading: Icon(Icons.video_file),
                title: Text(
                  "Pick video",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Camera",
                      onPressed: () => _pickVideo(true),
                      icon: Icon(Icons.camera),
                    ),
                    Gap(5),
                    IconButton(
                      tooltip: "Gallery",
                      onPressed: _pickVideo,
                      icon: Icon(Icons.image),
                    ),
                  ],
                ),
              ),
              ListTile(
                onTap: () {
                  isDeviceEncode.value = !isDeviceEncode.value;
                },
                title: const Text('Encode video on device'),
                leading: const Icon(Icons.emergency_outlined),
                trailing: VideoEncoderSwitch(
                  valueNotifier: isDeviceEncode,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Row _videoHeader(BuildContext context) {
    return Row(
                        children: [
                          Expanded(
                              child: Text(
                            file!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                          Gap(15),
                          TextButton.icon(
                              onPressed: () async {
                                File? file = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        VideoEditorScreen(
                                            file: File(this.file!.path)),
                                  ),
                                );
                                if (file != null && mounted) {
                                  setState(() {
                                    this.file = XFile(file.path);
                                  });
                                }
                              },
                              icon: Icon(
                                Icons.edit,
                                size: 18,
                              ),
                              label: Text("Edit Video"))
                        ],
                      );
  }

  void onNext(BuildContext context) {
    var data = context.read<HiveUserData>();
    if (file == null) {
      context.showSnackBar("Please pick video to proceed");
    } else {
      var screen;
      if (isDeviceEncode.value) {
        screen = ThumbnailPickerView(
          isCamera: false,
          appData: data,
          videoFile: file!,
          isDeviceEncode: isDeviceEncode.value,
        );
      } else {
        screen = VideoUploadScreen(
          isCamera: false,
          videoFile: file!,
          appData: data,
          isDeviceEncode: isDeviceEncode.value,
        );
      }
      if(!isDeviceEncode.value){
        Navigator.of(context).pop();
      }
      var route = MaterialPageRoute(builder: (c) => screen);
      Navigator.of(context).push(route);
    }
  }

  void _pickVideo([bool isCamera = false]) async {
    final XFile? file;
    file = await ImagePicker().pickVideo(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
    );
    if (file != null) {
      if (mounted) {
        setState(() {
          this.file = file;
        });
      }
    }
  }
}
