import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_upload/video_upload_prepare_response.dart';
import 'package:acela/src/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';

class VideoSaveMixin {
  ValueNotifier<String> savingText = ValueNotifier('Saving video info');
  ValueNotifier<bool> isSaving = ValueNotifier(false);

  Future<void> saveVideo(
    HiveUserData user,
    VideoUploadInfo item, {
    required String title,
    required String description,
    required bool isNsfwContent,
    required String tags,
    required String thumbIpfs,
    required String communityId,
    required List<BeneficiariesJson> beneficiaries,
    required VideoLanguage language,
    required bool isPowerUp100,
    required VoidCallback successDialog,
    required Function(String) errorSnackbar,
  }) async {
    try {
      isSaving.value = true;
      // TO-DO: Update here
      // await Communicator().updateInfo(
      //     user: user,
      //     videoId: item.id,
      //     title: title,
      //     description: description,
      //     isNsfwContent: isNsfwContent,
      //     tags: tags,
      //     thumbnail: thumbIpfs.isEmpty ? null : thumbIpfs,
      //     communityID: communityId);
      isSaving.value = false;
      successDialog();
    } catch (e) {
      isSaving.value = false;
      errorSnackbar(e.toString());
    }
  }
}
