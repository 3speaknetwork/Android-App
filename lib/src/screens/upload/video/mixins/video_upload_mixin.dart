import 'dart:developer';
import 'dart:io';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_upload/upload_response.dart';
import 'package:acela/src/models/video_upload/video_upload_prepare_response.dart';
import 'package:acela/src/screens/upload/video/encoding/folder_path.dart';
import 'package:acela/src/screens/upload/video/encoding/resolution.dart';
import 'package:acela/src/screens/upload/video/encoding/video_encoder.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/media_information_session.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tus_client/tus_client.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

mixin Upload {
  PageController pageController = PageController();
  ValueNotifier<double> videoUploadProgress = ValueNotifier(0);
  ValueNotifier<double> thumbnailUploadProgress = ValueNotifier(0);
  ValueNotifier<UploadStatus> uploadStatus = ValueNotifier(UploadStatus.idle);
  ValueNotifier<UploadStatus> thumbnailUploadStatus =
      ValueNotifier(UploadStatus.idle);
  ValueNotifier<UploadResponse?> thumbnailUploadResponse = ValueNotifier(null);

  int page = 0;
  late VideoUploadInfo uploadedVideoItem;

  void onUpload(
      {required XFile pickedVideoFile,
      required HiveUserData hiveUserData,
      required Function(String) onError}) async {
    var size = await pickedVideoFile.length();
    var originalFileName = pickedVideoFile.name;

    _initiateNextUpload();
    uploadStatus.value = UploadStatus.started;
    log('upload started');

    int fileSize = _checkFileSize(size);
    var path = pickedVideoFile.path;
    FolderPath().printFolderContent(FolderPath().path());
    encodeVideoAndThen(path, () async {
      var videoUploadReponse = await _uploadToServer(path, videoUploadProgress);
      var name = 'videoUploadReponse.name';
      _initiateNextUpload();
      var thumbPath = await _getThumbnail(path);
      _initiateNextUpload();
      var thumbReponse = await uploadThumbnail(thumbPath);
      _initiateNextUpload();

      log('Uploaded file name is $name');
      log('Uploaded thumbnail file name is ${thumbReponse.name}');
      uploadedVideoItem = await _encodeAndUploadInfo(path, hiveUserData,
          thumbReponse.name, originalFileName, fileSize, name);

      var zipPath = FolderPath().readZipFile().path;
      var string = await Communicator().uploadZip(
          permlink: uploadedVideoItem.permlink,
          user: hiveUserData,
          uploadZipFilePath: zipPath);
      debugPrint("We got data from server = $string");
      uploadStatus.value = UploadStatus.ended;
      _initiateNextUpload();
    }, onError);
  }

  bool isFreshUpload() {
    return uploadStatus.value == UploadStatus.idle;
  }

  void _initiateNextUpload() {
    if (pageController.hasClients) {
      page++;
      pageController.animateToPage(page,
          duration: const Duration(milliseconds: 250), curve: Curves.easeIn);
    } else {
      page++;
    }
  }

  void jumpToPage() {
    pageController.jumpToPage(
      page,
    );
  }

  Future<String> _getThumbnail(String path) async {
    try {
      FolderPath folderPath = FolderPath();
      var imagePath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: folderPath.path(),
        imageFormat: ImageFormat.PNG,
        maxWidth: 320,
        quality: 100,
      );
      if (imagePath == null) {
        throw 'Could not generate video thumbnail';
      }
      final thumbnailFile = File(imagePath);
      final newThumbnailPath = '${folderPath.path()}/thumbnail.png';

      await thumbnailFile.rename(newThumbnailPath);
      return newThumbnailPath;
    } catch (e) {
      throw 'Error generating video thumbnail ${e.toString()}';
    }
  }

  int _checkFileSize(int size) {
    var fileSize = size;
    var sizeInMb = fileSize / 1000 / 1000;
    log("Compressed video file size in mb is - $sizeInMb");
    if (sizeInMb > 1024) {
      throw 'Video is too big to be uploaded from mobile (exceeding 500 mb)';
    }
    return fileSize;
  }

  Future<UploadResponse> uploadThumbnail(String path) async {
    thumbnailUploadStatus.value = UploadStatus.started;
    var thumbReponse = await _uploadToServer(path, thumbnailUploadProgress);
    thumbnailUploadStatus.value = UploadStatus.ended;
    thumbnailUploadResponse.value = (thumbReponse);
    return thumbReponse;
  }

  Future<VideoUploadInfo> _encodeAndUploadInfo(
      String path,
      HiveUserData hiveUserData,
      String thumbName,
      String originalFileName,
      int fileSize,
      String name) async {
    MediaInformationSession session =
        await FFprobeKit.getMediaInformation(path);
    var info = session.getMediaInformation();
    var duration =
        (double.tryParse(info?.getDuration() ?? "0.0") ?? 0.0).toInt();

    return await Communicator().uploadInfo(
      user: hiveUserData,
      thumbnail: thumbName,
      oFilename: originalFileName,
      duration: duration,
      size: fileSize.toDouble(),
      tusFileName: name,
    );
  }

  Future<UploadResponse> _uploadToServer(
      String path, ValueNotifier<double> progressIndicator) async {
    final xfile = XFile(path);
    final client = TusClient(
      Uri.parse(Communicator.fsServer),
      xfile,
      store: TusMemoryStore(),
    );
    var name = "";
    var url = '';
    await client.upload(
      onComplete: () async {
        progressIndicator.value = 1.0;
        debugPrint("Complete!");
        debugPrint(client.uploadUrl.toString());
        url = client.uploadUrl.toString();
        var ipfsName = url.replaceAll("${Communicator.fsServer}/", "");
        name = ipfsName;
      },
      onProgress: (progress) {
        log("Progress: $progress");
        progressIndicator.value = progress / 100.0;
      },
    );
    return UploadResponse(name: name, url: url);
  }

  Future<void> encodeVideoAndThen(String filePath, VoidCallback onComplete,
      Function(String) onError) async {
    VideoEncoder encoder = VideoEncoder();
    VideoResolution? originalResolution =
        await encoder.getVideoResolution(filePath);
    List<VideoResolution> all =
        encoder.generateTargetResolutions(originalResolution!);
    await encoder.convertToMultipleResolutions(
        filePath, all, videoUploadProgress, onComplete, onError);
  }
}
