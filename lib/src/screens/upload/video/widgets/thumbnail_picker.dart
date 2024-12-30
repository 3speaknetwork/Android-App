import 'package:acela/src/models/video_upload/upload_response.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ThumbnailPicker extends StatefulWidget {
  const ThumbnailPicker(
      {Key? key,
      required this.thumbnailUploadProgress,
      required this.thumbnailUploadRespone,
      required this.onUploadFile,
      required this.thumbnailUploadStatus,
      required this.isDeviceEncode})
      : super(key: key);

  final ValueNotifier<double> thumbnailUploadProgress;
  final ValueNotifier<UploadResponse?> thumbnailUploadRespone;
  final Function(XFile) onUploadFile;
  final bool isDeviceEncode;
  final ValueNotifier<UploadStatus> thumbnailUploadStatus;

  @override
  State<ThumbnailPicker> createState() => _ThumbnailPickerState();
}

class _ThumbnailPickerState extends State<ThumbnailPicker> {
  bool isPickingImage = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<UploadStatus>(
      valueListenable: widget.thumbnailUploadStatus,
      builder: (context, uploadStatus, child) {
        return InkWell(
          child: Padding(
            padding: const EdgeInsets.all(kScreenHorizontalPaddingDigit),
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.emergency,
                          size: 15,
                          color: Colors.red,
                        )),
                    Container(
                      color: theme.cardColor.withOpacity(0.5),
                      width: 320,
                      height: 160,
                      child: ValueListenableBuilder<double>(
                        valueListenable: widget.thumbnailUploadProgress,
                        builder: (context, progress, child) {
                          return Center(
                            child: uploadStatus == UploadStatus.started
                                ? CircularProgressIndicator(
                                    value: progress,
                                    valueColor: AlwaysStoppedAnimation<Color?>(
                                        theme.primaryColorLight),
                                    backgroundColor: !isPickingImage
                                        ? theme.primaryColorLight
                                            .withOpacity(0.4)
                                        : null,
                                  )
                                : ValueListenableBuilder<UploadResponse?>(
                                    valueListenable:
                                        widget.thumbnailUploadRespone,
                                    builder: (context, value, child) {
                                      return value != null
                                          ? widget.isDeviceEncode
                                              ? Image.asset(value.url)
                                              : Image.network(value.url)
                                          : const SizedBox.shrink();
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
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
          onTap: () async {
            await _onTap(uploadStatus);
          },
        );
      },
    );
  }

  Future<void> _onTap(UploadStatus uploadStatus) async {
    if (uploadStatus != UploadStatus.started) {
      try {
        setState(() {
          isPickingImage = true;
        });
        final XFile? file =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (file != null) {
          setState(() {
            isPickingImage = false;
          });
          widget.onUploadFile(file);
        } else {
          throw 'User cancelled image picker';
        }
      } catch (e) {
        showError(e.toString());
        setState(() {
          isPickingImage = false;
        });
      }
    }
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
