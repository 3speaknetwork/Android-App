import 'dart:io';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/my_account/my_account_screen.dart';
import 'package:acela/src/screens/upload/video/controller/video_upload_controller.dart';
import 'package:acela/src/screens/upload/video/widgets/beneficaries_tile.dart';
import 'package:acela/src/screens/upload/video/widgets/community_picker.dart';
import 'package:acela/src/screens/upload/video/widgets/confirm_schedule_time_dialog.dart';
import 'package:acela/src/screens/upload/video/widgets/language_tile.dart';
import 'package:acela/src/screens/upload/video/widgets/publish_fab.dart';
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
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:provider/provider.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen(
      {Key? key,
      required this.appData,
      required this.isCamera,
      required this.isDeviceEncode,
      this.thumbnailFile,
      this.videoFile})
      : super(key: key);

  final HiveUserData appData;

  final bool isCamera;
  final bool isDeviceEncode;
  final File? thumbnailFile;
  final XFile? videoFile;
  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController tagsController;

  DateTime? scheduledTime;

  @override
  void initState() {
    final controller = context.read<VideoUploadController>();
    controller.pickedThumbnail = widget.thumbnailFile;
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
      floatingActionButtonLocation: ExpandableFab.location,
      resizeToAvoidBottomInset: false,
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
                        finalUploadProgress: controller.finalUploadProgress,
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
                    if (!controller.isDeviceEncoding)
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
      isDeviceEncode: controller.isDeviceEncoding,
      thumbnailUploadStatus: controller.thumbnailUploadStatus,
      thumbnailUploadProgress: controller.thumbnailUploadProgress,
      thumbnailUploadRespone: controller.thumbnailUploadResponse,
      onUploadFile: (file) {
        if (controller.isDeviceEncoding) {
        } else {
          controller.uploadThumbnail(file.path);
        }
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
        await controller.onUpload(
            isDeviceEncoding: controller.isDeviceEncoding,
            hiveUserData: widget.appData,
            pickedVideoFile: widget.videoFile!,
            onError: (e) => _onError(e, context, controller));
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

  void showSuccessDialog(
    bool hasPostingAuthority, {
    required VoidCallback resetControllerCallback,
    required bool publishLater,
    required bool scheduleLater,
  }) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (c) => VideoUploadSucessDialog(
              publishLater: publishLater,
              hasPostingAuthority: hasPostingAuthority,
              scheduleLater: scheduleLater,
            )).whenComplete(() {
      resetControllerCallback();
      Navigator.pop(context);
      if (!hasPostingAuthority || publishLater) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyAccountScreen(
              data: widget.appData,
              initialTabIndex: publishLater ? 0 : 2,
            ),
          ),
        );
      }
    });
  }

  Future<void> _pickDateTime(VideoUploadController controller) async {
    final DateTime now = DateTime.now();
    final DateTime minAllowedTime = now.add(Duration(minutes: 59));
    DateTime? picked = await showOmniDateTimePicker(
      context: context,
      initialDate: scheduledTime ?? minAllowedTime,
      firstDate: minAllowedTime,
      lastDate: now.add(Duration(days: 31)),
      is24HourMode: false,
      isShowSeconds: false,
    );

    if (picked != null) {
      if (picked.isBefore(now.add(Duration(minutes: 59)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please pick a time at least 1 hour from now."),
          ),
        );
        return;
      }
      scheduledTime = picked;
      _showConfirmationDialog(picked, controller);
    }
  }

  void _showConfirmationDialog(
      DateTime picked, VideoUploadController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmSceduleTimeDialog(
          dateTime: picked,
          onConfirm: () {
            Navigator.of(context).pop();
            _save(controller, false, picked);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          onPickAgain: () {
            Navigator.of(context).pop();
            _pickDateTime(controller);
          },
        );
      },
    );
  }

  Widget saveButton(VideoUploadController controller) {
    return ValueListenableBuilder<bool>(
        valueListenable: controller.isSaving,
        builder: (context, isPulishing, child) {
          return Visibility(visible: !isPulishing, child: child!);
        },
        child: PublishFab(
          isDeviceEncode: widget.isDeviceEncode,
          onPublishNow: () => _save(controller, false),
          onPublishLater: () => _save(controller, true),
          onSchedulePublish: () => validate(controller, () {
            _pickDateTime(controller);
          }),
        ));
  }

  Future<void> _save(VideoUploadController controller, bool publishLater,
      [DateTime? scheduledDate]) async {
    validate(controller, () async {
      return await controller.validateAndSaveVideo(widget.appData,
          successDialog: (hasPostingAuthority) => showSuccessDialog(
              scheduleLater: scheduledDate != null,
              hasPostingAuthority,
              publishLater: publishLater,
              resetControllerCallback: controller.resetController),
          successSnackbar: (message) => showMessage(
                message,
              ),
          errorSnackbar: (message) => showError(message),
          publishLater: publishLater,
          scheduledData: scheduledDate);
    });
  }

  void validate(
    VideoUploadController controller,
    VoidCallback onValidate,
  ) {
    if (controller.uploadStatus.value != UploadStatus.ended) {
      showMessage('Only after the video is upload, you can pulish the video');
    } else if (controller.title.isEmpty) {
      showMessage('Title is Required');
    } else if (controller.description.isEmpty) {
      showMessage('Description is Required');
    } else if (controller.thumbnailUploadResponse.value == null &&
        !controller.isDeviceEncoding) {
      showMessage('Thumbnail is Required');
    } else {
      onValidate();
    }
  }
}
