import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/settings/settings_screen.dart';
import 'package:acela/src/screens/upload/video/mixins/video_save_mixin.dart';
import 'package:acela/src/screens/upload/video/mixins/video_upload_mixin.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';

class VideoUploadController extends ChangeNotifier with Upload, VideoSaveMixin {
  String title = '';
  String description = '';
  String tags = '';
  String communityName = '';
  String communityId = '';
  bool isNsfwContent = false;
  bool isPower100 = false;
  List<BeneficiariesJson> beneficaries = [];
  String userName = '';
  late VideoLanguage language;

  VideoUploadController() {
    setCommunity();
    setLanguage();
  }

  void setCommunity({
    String? communityName,
    String? communityId,
  }) {
    this.communityName = communityName ?? 'Three Speak';
    this.communityId = communityId ?? 'hive-181335';
  }

  void setTags({String? tags}) {
    String defaultTag = 'threespeak,mobile';
    this.tags = tags ?? defaultTag;
    if (!this.tags.contains(defaultTag)) {
      if (this.tags.isEmpty) {
        this.tags = '$defaultTag';
      } else {
        this.tags = '${this.tags},$defaultTag';
      }
    }
  }

  void setBeneficiares({String? userName, bool resetBeneficiares = false}) {
    this.userName = userName ?? this.userName;
    if (beneficaries.isEmpty || resetBeneficiares) {
      if (this.userName != 'sagarkothari88') {
        beneficaries.add(
          BeneficiariesJson(
              account: 'sagarkothari88',
              src: 'mobile',
              weight: 1,
              isDefault: true),
        );
      }
      if (this.userName != 'spk.beneficiary') {
        beneficaries.add(BeneficiariesJson(
            account: 'spk.beneficiary',
            src: 'threespeak',
            weight: 9,
            isDefault: true));
      }
      if (this.userName != 'threespeakleader') {
        beneficaries.add(BeneficiariesJson(
            account: 'threespeakleader',
            src: 'threespeak',
            weight: 1,
            isDefault: true));
      }
      beneficaries.add(
        BeneficiariesJson(account: this.userName, src: 'author', weight: 89),
      );
    }
  }

  void setLanguage({VideoLanguage? language}) {
    this.language = language ?? VideoLanguage(code: "en", name: "English");
  }

  Future<void> validateAndSaveVideo(
    HiveUserData userData, {
    required VoidCallback successDialog,
    required Function(String) successSnackbar,
    required Function(String) errorSnackbar,
  }) async {
    if (uploadStatus.value != UploadStatus.ended) {
      errorSnackbar('Only after the video is upload, you can pulish the video');
    } else if (title.isEmpty) {
      errorSnackbar('Title is Required');
    } else if (description.isEmpty) {
      errorSnackbar('Description is Required');
    } else if (thumbnailUploadResponse.value == null) {
      errorSnackbar('Thumbnail is Required');
    } else {
      await saveVideo(userData, uploadedVideoItem,
          title: title,
          description: description,
          tags: tags,
          beneficiaries: beneficaries,
          communityId: communityId,
          isNsfwContent: isNsfwContent,
          language: language,
          isPowerUp100: isPower100,
          thumbIpfs: thumbnailUploadResponse.value!.name,
          successDialog: successDialog,
          errorSnackbar: errorSnackbar);
    }
  }

  void resetController() {
    page = 0;
    thumbnailUploadProgress.value = 0;
    videoUploadProgress.value = 0;
    uploadStatus.value = UploadStatus.idle;
    pageController.dispose();
    pageController = PageController();
    title = '';
    description = '';
    setCommunity();
    setTags();
    isNsfwContent = false;
    setBeneficiares(resetBeneficiares: true);
    setLanguage();
    thumbnailUploadResponse = ValueNotifier(null);
    thumbnailUploadStatus.value = UploadStatus.idle;
    isSaving.value = false;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
