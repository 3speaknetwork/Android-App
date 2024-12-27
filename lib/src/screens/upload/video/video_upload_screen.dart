import 'dart:io';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/my_account/my_account_screen.dart';
import 'package:acela/src/screens/upload/video/controller/video_upload_controller.dart';
import 'package:acela/src/screens/upload/video/widgets/beneficaries_tile.dart';
import 'package:acela/src/screens/upload/video/widgets/community_picker.dart';
import 'package:acela/src/screens/upload/video/widgets/language_tile.dart';
import 'package:acela/src/screens/upload/video/widgets/reward_type_widget.dart';
import 'package:acela/src/screens/upload/video/widgets/thumbnail_picker.dart';
import 'package:acela/src/screens/upload/video/widgets/uploadProgressExpansionTile.dart';
import 'package:acela/src/screens/upload/video/widgets/upload_textfield.dart';
import 'package:acela/src/screens/upload/video/widgets/video_upload_divider.dart';
import 'package:acela/src/screens/upload/video/widgets/video_upload_success_dialog.dart';
import 'package:acela/src/screens/upload/video/widgets/work_type_widget.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:images_picker/images_picker.dart';
import 'package:provider/provider.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen(
      {Key? key,
      required this.appData,
      required this.isCamera,
      required this.isDeviceEncode})
      : super(key: key);

  final HiveUserData appData;

  final bool isCamera;
  final bool isDeviceEncode;
  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController tagsController;

  @override
  void initState() {
    final controller = context.read<VideoUploadController>();
    titleController = TextEditingController(text: controller.title);
    descriptionController = TextEditingController(text: controller.description);
    tagsController = TextEditingController(text: controller.tags);
    controller.setBeneficiares(
        userName: context.read<HiveUserData>().username!);
    controller.isDeviceEncoding = widget.isDeviceEncode;
    super.initState();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<VideoUploadController>();
    return Scaffold(
      appBar: AppBar(title: Text("Upload your video")),
      floatingActionButton: saveButton(controller),
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.isSaving,
              builder: (context, isPublishing, child) {
                if (isPublishing) {
                  return Center(
                      child: ValueListenableBuilder<String>(
                    valueListenable: controller.savingText,
                    builder: (context, publishingText, child) {
                      return LoadingScreen(
                        title: 'Please wait',
                        subtitle: publishingText,
                      );
                    },
                  ));
                } else {
                  return child!;
                }
              },
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    UploadProgressExpandableTile(
                        currentPage: controller.page,
                        pageController: controller.pageController,
                        mediaUploadProgress: controller.videoUploadProgress,
                        thumbnailUploadProgress:
                            controller.thumbnailUploadProgress,
                        uploadStatus: controller.uploadStatus,
                        isLocalEncode: widget.isDeviceEncode,
                        onUpload: () {
                          _onUpload(context, controller);
                        }),
                    const SizedBox(height: 15),
                    UploadTextField(
                        textEditingController: titleController,
                        hintText: 'Video title goes here',
                        labelText: 'Title',
                        minLines: 1,
                        maxLines: 1,
                        maxLength: 150,
                        onChanged: (value) {
                          controller.title = value;
                        }),
                    const SizedBox(
                      height: 10,
                    ),
                    UploadTextField(
                        textEditingController: tagsController,
                        hintText: 'threespeak,mobile',
                        labelText: 'Tags',
                        maxLines: 1,
                        minLines: 1,
                        maxLength: 150,
                        onChanged: (value) {
                          controller.setTags(tags: value);
                        }),
                    const SizedBox(
                      height: 10,
                    ),
                    UploadTextField(
                        textEditingController: descriptionController,
                        hintText: 'Video description',
                        labelText: 'Description',
                        maxLines: 8,
                        minLines: 5,
                        onChanged: (value) {
                          controller.description = value;
                        }),
                    communityTile(controller),
                    const VideoUploadDivider(),
                    _workType(controller),
                    const VideoUploadDivider(),
                    _rewardType(controller),
                    const VideoUploadDivider(),
                    _beneficiaryTile(controller),
                    const VideoUploadDivider(),
                    _languageTile(controller),
                    const VideoUploadDivider(),
                    _thumbnailPicker(controller),
                    const SizedBox(
                      height: 50,
                    )
                  ],
                ),
              ),
            )),
      ),
    );
  }

  ThumbnailPicker _thumbnailPicker(VideoUploadController controller) {
    return ThumbnailPicker(
      thumbnailUploadStatus: controller.thumbnailUploadStatus,
      thumbnailUploadProgress: controller.thumbnailUploadProgress,
      thumbnailUploadRespone: controller.thumbnailUploadResponse,
      onUploadFile: (file) {
        controller.uploadThumbnail(file.path);
      },
    );
  }

  LanguageTile _languageTile(VideoUploadController controller) {
    return LanguageTile(
        selectedLanguage: controller.language,
        onChanged: (value) {
          controller.setLanguage(language: value);
        });
  }

  Widget _workType(VideoUploadController controller) {
    return WorkTypeWidget(
      isNsfwContent: controller.isNsfwContent,
      onChanged: (newValue) {
        controller.isNsfwContent = newValue;
      },
    );
  }

  Widget communityTile(VideoUploadController controller) {
    return CommunityPicker(
      communityName: controller.communityName,
      communityId: controller.communityId,
      onChanged: (name, id) {
        controller.setCommunity(communityName: name, communityId: id);
      },
    );
  }

  Widget _rewardType(VideoUploadController controller) {
    return RewardTypeWidget(
        isPower100: controller.isPower100,
        onChanged: (value) {
          controller.isPower100 = value;
        });
  }

  Widget _beneficiaryTile(VideoUploadController controller) {
    return BeneficiariesTile(
      userName: context.read<HiveUserData>().username!,
      beneficiaries: controller.beneficaries,
      onChanged: (beneficaries) => controller.beneficaries = beneficaries,
    );
  }

  Future<void> _onUpload(
      BuildContext context, VideoUploadController controller) async {
    controller.jumpToPage();
    if (controller.uploadStatus.value == UploadStatus.idle) {
      try {
        final XFile? file;
        // file = null;
        file = await ImagePicker().pickVideo(
          source: widget.isCamera ? ImageSource.camera : ImageSource.gallery,
          preferredCameraDevice: CameraDevice.front,
        );

        if (file != null) {
          var fileToSave = File(file.path);
          if (widget.isCamera) {
            ImagesPicker.saveVideoToAlbum(fileToSave);
          }
         await controller.onUpload(
              isDeviceEncoding: controller.isDeviceEncoding,
              hiveUserData: widget.appData,
              pickedVideoFile: file,
              onError: (e) => _onError(e, context, controller));
        } else {
          showMessage('Video Picker Cancelled');
          Navigator.pop(context);
        }
      } catch (e) {
        _onError(e, context, controller);
      }
    }
  }

  void _onError(
      dynamic e, BuildContext context, VideoUploadController controller) {
    showMessage(e.toString());
    Navigator.pop(context);
    controller.resetController();
  }

  void showMessage(
    String string,
  ) {
    var snackBar = SnackBar(content: Text('Message: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSuccessDialog(bool hasPostingAuthority,
      {required VoidCallback resetControllerCallback}) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (c) => VideoUploadSucessDialog(
              hasPostingAuthority: hasPostingAuthority,
            )).whenComplete(() {
      resetControllerCallback();
      Navigator.pop(context);
      if (!hasPostingAuthority) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAccountScreen(
              data: widget.appData,
              initialTabIndex: 2,
            ),
          ),
        );
      }
    });
  }

  Widget saveButton(VideoUploadController controller) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSaving,
      builder: (context, isPulishing, child) {
        return Visibility(visible: !isPulishing, child: child!);
      },
      child: FloatingActionButton.extended(
          onPressed: () {
            controller.validateAndSaveVideo(widget.appData,
                successDialog: (hasPostingAuthority) => showSuccessDialog(
                    hasPostingAuthority,
                    resetControllerCallback: controller.resetController),
                successSnackbar: (message) => showMessage(
                      message,
                    ),
                errorSnackbar: (message) => showError(message));
          },
          label: Text("Save")),
    );
  }
}
