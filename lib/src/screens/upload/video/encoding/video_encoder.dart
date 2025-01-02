import 'dart:async';
import 'dart:developer';
import 'package:acela/src/screens/upload/video/encoding/folder_path.dart';
import 'package:acela/src/screens/upload/video/encoding/resolution.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffprobe_kit.dart' as ffprobe;
import 'package:ffmpeg_kit_flutter_https_gpl/media_information_session.dart';
import 'package:flutter/foundation.dart';

class VideoEncoder {
  static List<int> allResolutions = [720, 480];

  static String testFolderPath = '/storage/emulated/0/Download/$foldername';

  static String testPath = '/storage/emulated/0/Download';

  static String foldername = 'encoded_videos';
  static String zipFileName = "video.zip";

  late MediaInformationSession info;

  Future<VideoResolution?> getVideoResolution(String filePath) async {
    int rotation = await getVideoRotation(filePath);

    int width =
        info.getMediaInformation()!.getAllProperties()!['streams'][0]['width'];
    int height =
        info.getMediaInformation()!.getAllProperties()!['streams'][0]['height'];

    if (rotation == 90 ||
        rotation == 270 ||
        rotation == -90 ||
        rotation == -270) {
      int temp = width;
      width = height;
      height = temp;
    }

    bool isLandscape = width > height;
    return VideoResolution(
        originalHeight: height,
        originalWidth: width,
        width: getEvenDigit(width),
        height: getEvenDigit(height),
        isLandscape: isLandscape,
        convertVideo: !VideoEncoder.allResolutions
            .contains(isLandscape ? width : height));
  }

  Future<int> getVideoRotation(String filePath) async {
    try {
      info = await ffprobe.FFprobeKit.getMediaInformation(filePath);
      var properties = info.getMediaInformation()?.getAllProperties();

      if (properties?['streams'] is List &&
          properties!['streams'].isNotEmpty &&
          properties['streams'][0]['side_data_list'] is List &&
          properties['streams'][0]['side_data_list'].isNotEmpty &&
          properties['streams'][0]['side_data_list'][0]['rotation'] != null) {
        return properties['streams'][0]['side_data_list'][0]['rotation'];
      }
      return 0;
    } catch (e) {
      print('Error retrieving video rotation: $e');
      return 0;
    }
  }

  VideoResolution getResolution(
      VideoResolution resolution, int targetResolution) {
    if (resolution.isLandscape) {
      // int target =
      //     ((targetResolution * resolution.height) / resolution.width).round();
      int target = ((targetResolution * resolution.width) / resolution.height).round();
      var res = VideoResolution(
          width: getEvenDigit(target),
          height: targetResolution,
          isLandscape: resolution.isLandscape);
      return res;
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
        targetResolutions.removeWhere((element) {
          int originalResolutionNum =
              originalResolution.isLandscape ? element.width : element.height;
          bool notContains =
              !VideoEncoder.allResolutions.contains(originalResolutionNum);
          if (notContains && VideoEncoder.allResolutions.length >= 2) {
            if (originalResolutionNum < VideoEncoder.allResolutions.first &&
                originalResolutionNum > VideoEncoder.allResolutions[1]) {
              return false;
            }
          }
          return notContains;
        });
      }
    }
    log(targetResolutions.toString());
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
        return originalResolution.height >= resolution;
    // if (originalResolution.isLandscape) {
    //   return originalResolution.width >= resolution;
    // } else {
    //     return originalResolution.height >= resolution;
    // }
  }

  Future convertToMultipleResolutions(
      String inputPath,
      List<VideoResolution> targetResolutions,
      ValueNotifier<double> progressListener,
      VoidCallback onComplete,
      Function(double) duration,
      Function(String) onError) async {
    FolderPath folderPath = FolderPath();
    await folderPath.deleteDirectory();
    String encodingPath = await folderPath.createFolder();

    List<double> progressList = List.filled(2, 0.0);
    List<String> scales = ['480', '720'];

    StreamController<double> combinedProgressStream =
        StreamController<double>();

    await _progressListener(
        combinedProgressStream, progressListener, onComplete, onError);

    for (int i = 0; i < scales.length; i++) {
      debugPrint(
          '${i + 1} encoding started for resolution ${scales[i]}');
      await encodeVideo(
          inputPath,
          encodingPath,
          scales[i],
          () => combinedProgressStream.isClosed,
          duration, (individualProgress, session) async {
        progressList[i] = individualProgress;
        double combinedProgress =
            progressList.reduce((a, b) => a + b) / 2;
        if (!combinedProgressStream.isClosed) {
          combinedProgressStream.add(combinedProgress);
        } else {
          session?.cancel();
        }
      }, onError);
      debugPrint(
          '${i + 1} encoding ended for resolution ${scales[i]}');
      if (i == 2 - 1) {
        folderPath.generateMasterManifest(encodingPath, targetResolutions);
      }
    }
  }

  Future<void> _progressListener(
      StreamController<double> combinedProgressStream,
      ValueNotifier<double> progressListener,
      VoidCallback onComplete,
      Function(String) onError) async {
    await combinedProgressStream.stream.listen((combinedProgress) async {
      try {
        progressListener.value = combinedProgress / 100;
        debugPrint("Overall Progress: ${combinedProgress.toStringAsFixed(2)}%");
        if (combinedProgress == 100) {
          combinedProgressStream.close();

          onComplete();
        }
      } catch (e) {
        combinedProgressStream.close();
        onError(e.toString());
      }
    }, onError: (e) {
      combinedProgressStream.close();
      onError(e.toString());
    }, cancelOnError: true);
  }

  Future<void> encodeVideo(
      String inputPath,
      String outputPath,
      // VideoResolution resolution,
      String scale,
      bool Function() isStreamCancelled,
      Function(double) setDuration,
      Function(double, FFmpegSession?) onProgressUpdate,
      Function(String) onError) async {
    String command;
    command =
          '-i $inputPath -vf scale=${scale}:-2,setsar=1:1 -c:v libx264 -crf 20 -b:v 8M -start_number 0 -hls_time 10 -hls_list_size 0 -f hls $outputPath/${scale}p_video.m3u8';
    // if (resolution.convertVideo) {
      
    // } else {
    //   command =
    //       '-i $inputPath -codec: copy -start_number 0 -hls_time 10 -hls_list_size 0 -f hls $outputPath/${VideoResolution.quality(resolution)}p_video.m3u8';
    // }
    String? duratio = info.getMediaInformation()?.getDuration();
    setDuration(double.parse(duratio!));
    FFmpegSession? session;
    session = await FFmpegKit.executeAsync(
      command,
      (session) {
        if (!isStreamCancelled()) {
          onProgressUpdate(100, session);
          debugPrint('Video encoding completed successfully');
        }
      },
      (log) {},
      (statistics) async {
        double progress =
            ((statistics.getTime()) ~/ double.parse(duratio)) / 10;
        if (isStreamCancelled()) {
          session?.cancel();
          onProgressUpdate(progress, session);
          debugPrint('stream closed session cancelled');
          return;
        } else {
          onProgressUpdate(progress, null);
        }
      },
    ).catchError((e) {
      onError(e.toString());
    });
  }
}
