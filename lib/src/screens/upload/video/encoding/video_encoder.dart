import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/screens/upload/video/encoding/folder_path.dart';
import 'package:acela/src/screens/upload/video/encoding/resolution.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffprobe_kit.dart' as ffprobe;
import 'package:ffmpeg_kit_flutter_https_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/session.dart';
import 'package:flutter/foundation.dart';

class VideoEncoder {
  static List<int> allResolutions = [1080, 720, 480];

  static String testFolderPath = '/storage/emulated/0/Download/$foldername';

  static String testPath = '/storage/emulated/0/Download';

  static String foldername = 'encoded_videos';
  static String zipFileName = "video.zip";

  Future<VideoResolution?> getVideoResolution(String filePath) async {
    var execution = await ffprobe.FFprobeKit.execute(
      '-v error -select_streams v:0 -show_entries stream=width,height -of json -i $filePath',
    );

    String output = await execution.getOutput() ?? '';
    Map<String, dynamic> jsonMap = json.decode(output);

    int width = jsonMap['streams'][0]['width'];
    int height = jsonMap['streams'][0]['height'];

    bool isLandscape = width > height;
    return VideoResolution(
        width: getEvenDigit(width),
        height: getEvenDigit(height),
        isLandscape: isLandscape,
        convertVideo: !VideoEncoder.allResolutions
            .contains(isLandscape ? width : height));
  }

  VideoResolution getResolution(
      VideoResolution resolution, int targetResolution) {
    if (resolution.isLandscape) {
      int target =
          ((targetResolution * resolution.height) / resolution.width).round();
      return VideoResolution(
          width: targetResolution,
          height: getEvenDigit(target),
          isLandscape: resolution.isLandscape);
    } else {
      int target =
          ((targetResolution * resolution.width) / resolution.height).round();
      return VideoResolution(
          width: getEvenDigit(target),
          height: targetResolution,
          isLandscape: resolution.isLandscape);
    }
  }

  int getEvenDigit(int number) {
    return number.isOdd ? (number + 1) ~/ 2 * 2 : number;
  }

  List<VideoResolution> generateTargetResolutions(
    VideoResolution originalResolution,
  ) {
    debugPrint(originalResolution.toString());
    List<VideoResolution> targetResolutions = [originalResolution];

    for (int resolution in VideoEncoder.allResolutions) {
      if (!isTargetSolutionAlreadyContainResolution(
              targetResolutions, resolution) &&
          isOriginalResolutionGreater(
            resolution,
            originalResolution,
          )) {
        targetResolutions
            .add(getResolution(targetResolutions.last, resolution));
        targetResolutions.removeWhere((element) => !VideoEncoder.allResolutions
            .contains(originalResolution.isLandscape
                ? element.width
                : element.height));
      }
    }
    debugPrint(targetResolutions.toString());
    return targetResolutions;
  }

  bool isTargetSolutionAlreadyContainResolution(
      List<VideoResolution> resolutions, int targetResolution) {
    for (var item in resolutions) {
      bool isLandscape = item.isLandscape;
      if (isLandscape) {
        return item.width == targetResolution;
      } else {
        return item.height == targetResolution;
      }
    }
    return false;
  }

  isOriginalResolutionGreater(
      int resolution, VideoResolution originalResolution) {
    if (originalResolution.isLandscape) {
      return originalResolution.width >= resolution;
    } else {
      return originalResolution.height >= resolution;
    }
  }

  Future convertToMultipleResolutions(
      String inputPath,
      List<VideoResolution> targetResolutions,
      ValueNotifier<double> progressListener,
      VoidCallback onComplete) async {
    FolderPath folderPath = FolderPath();
    await folderPath.deleteDirectory();
    String encodingPath = await folderPath.createFolder();
    List<double> progressList = List.filled(targetResolutions.length, 0.0);
    StreamController<double> combinedProgressStream =
        StreamController<double>();

    combinedProgressStream.stream.listen((combinedProgress) async {
      try {
        // throw Exception('error');
        progressListener.value = combinedProgress / 100;
        debugPrint("Overall Progress: ${combinedProgress.toStringAsFixed(2)}%");
        if (combinedProgress == 100) {
          combinedProgressStream.close();
          await folderPath.zipFolder(encodingPath);
          folderPath.printFolderContent(encodingPath);
          print(folderPath.printM3u8Contents());
          print(folderPath.printFolderContent(encodingPath));
          onComplete();
        }
      } catch (e) {
        combinedProgressStream.close();
        log("error ${e.toString()}");
        rethrow;
      }
    }, onError: (e) {
      throw e;
    });
    for (int i = 0; i < targetResolutions.length; i++) {
      VideoResolution resolution = targetResolutions[i];

      debugPrint(
          '${i + 1} encoding stared for resolution ${resolution.resolution}');
      await encodeVideo(
        inputPath,
        encodingPath,
        resolution,
        () => combinedProgressStream.isClosed,
        (individualProgress, session) {
          progressList[i] = individualProgress;
          double combinedProgress =
              progressList.reduce((a, b) => a + b) / targetResolutions.length;
          if (!combinedProgressStream.isClosed) {
            combinedProgressStream.add(combinedProgress);
          } else {
            session?.cancel();
          }
        },
      );
      debugPrint(
          '${i + 1} encoding ended for resolution ${resolution.resolution}');
      if (i == targetResolutions.length - 1) {
        folderPath.generateMasterManifest(encodingPath, targetResolutions);
      }
    }
  }

  Future<void> encodeVideo(
    String inputPath,
    String outputPath,
    VideoResolution resolution,
    bool Function() isStreamCancelled,
    Function(double, FFmpegSession?) onProgressUpdate,
  ) async {
    String command;
    if (resolution.convertVideo) {
      command =
          '-i $inputPath -vf scale=${resolution.width}:${resolution.height} -vcodec libx264 -start_number 0 -hls_time 10 -hls_list_size 0 -f hls $outputPath/${VideoResolution.quality(resolution)}p_video.m3u8';
    } else {
      command =
          '-i $inputPath -codec: copy -start_number 0 -hls_time 10 -hls_list_size 0 -f hls $outputPath/${VideoResolution.quality(resolution)}p_video.m3u8';
    }
    MediaInformationSession info =
        await ffprobe.FFprobeKit.getMediaInformation(inputPath);
    String? duratio = info.getMediaInformation()?.getDuration();
    FFmpegSession? session;
    session = await FFmpegKit.executeAsync(
      command,
      (session) {
        onProgressUpdate(100, session);
        debugPrint('Video encoding completed successfully');
      },
      (log) {},
      (statistics) {
        if (isStreamCancelled()) {
          session?.cancel();
          log('stream closed session cancelled');
          return;
        }
        double progress =
            ((statistics.getTime()) ~/ double.parse(duratio!)) / 10;
        onProgressUpdate(progress, null);
      },
    ).catchError((e) {
      log('error ${e.toString()}');
      throw e;
    });
  }
}