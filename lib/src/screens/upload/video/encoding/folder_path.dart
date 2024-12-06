import 'dart:io';

import 'package:acela/src/screens/upload/video/encoding/resolution.dart';
import 'package:acela/src/screens/upload/video/encoding/video_encoder.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

class FolderPath {
  String getStorageDirectory() {
    Directory appDocDir = Directory.systemTemp;
    return appDocDir.path;
  }

  String path() =>
      "${getStorageDirectory()}/${VideoEncoder.foldername}";

  Future<String> createFolder({String? customFolderPath}) async {
    String internalStoragePath =
        customFolderPath ?? getStorageDirectory();
    String folderPath = '$internalStoragePath/${VideoEncoder.foldername}';

    Directory folder = Directory(folderPath);
    // if (!(await folder.exists())) {
    await folder.create();
    // }

    return folderPath;
  }

  Future<void> printM3u8Contents() async {
    String rootPath = getStorageDirectory();
    Directory folder =
        Directory("$rootPath/${VideoEncoder.foldername}/manifest.m3u8");
    String filePath = folder.path;
    File file = File(filePath);
    if (await file.exists()) {
      try {
        String contents = await file.readAsString();
        debugPrint("M3U8 File Contents:\n");
        debugPrint(contents);
      } catch (e) {
        debugPrint("Error reading the file: $e");
      }
    } else {
      debugPrint("File not found at path: $filePath");
    }
  }

  Future<bool> printFolderContent(String path) async {

    Directory folder = Directory(path);
    bool result = await folder.exists();

    if (result) {
      debugPrint("Folder exists: $path");
      debugPrint("Listing all files and folders:");
      try {
        await for (var entity in folder.list()) {
          debugPrint(entity.path);
        }
      } catch (e) {
        debugPrint("Error listing files: $e");
      }
    } else {
      debugPrint("Folder does not exist.");
    }

    return result;
  }

  Future<void> deleteDirectory() async {
    String rootPath = await getStorageDirectory();
    Directory folder = Directory("$rootPath/${VideoEncoder.foldername}");
    if (await folder.exists()) {
      folder.deleteSync(recursive: true);
      debugPrint(
          'Directory and its contents deleted: ${VideoEncoder.foldername}');
    }
  }

  void generateMasterManifest(
      String manifestPath, List<VideoResolution> resolutions) {
    String masterManifestPath = '$manifestPath/manifest.m3u8';

    File masterManifestFile = File(masterManifestPath);

    RandomAccessFile masterManifestAccessFile =
        masterManifestFile.openSync(mode: FileMode.write);

    masterManifestAccessFile.writeStringSync('#EXTM3U\n');
    masterManifestAccessFile.writeStringSync('#EXT-X-VERSION:3\n');
    for (var resolution in resolutions) {
      if (resolution.resolution == '1080p') {
        masterManifestAccessFile.writeStringSync(
            '#EXT-X-STREAM-INF:BANDWIDTH=2000000,CODECS="mp4a.40.2",RESOLUTION=${resolution.width}x${resolution.height},NAME=1080\n');
        masterManifestAccessFile
            .writeStringSync('${resolution.resolution}_video.m3u8\n');
      } else if (resolution.resolution == '720p') {
        masterManifestAccessFile.writeStringSync(
            '#EXT-X-STREAM-INF:BANDWIDTH=1327000,CODECS="mp4a.40.2",RESOLUTION=${resolution.width}x${resolution.height},NAME=720\n');
        masterManifestAccessFile
            .writeStringSync('${resolution.resolution}_video.m3u8\n');
      } else {
        String resolutionName = resolution.resolution.replaceAll('p', '');
        masterManifestAccessFile.writeStringSync(
            '#EXT-X-STREAM-INF:BANDWIDTH=763000,CODECS="mp4a.40.2",RESOLUTION=${resolution.width}x${resolution.height},NAME=$resolutionName\n');
        masterManifestAccessFile
            .writeStringSync('${resolution.resolution}_video.m3u8\n');
      }
    }
    masterManifestAccessFile.closeSync();
    debugPrint('Master Manifest generated');
  }

  void createZip(String sourcePath, String zipFilePath) {
    ZipFileEncoder archiveBuilder = ZipFileEncoder();
    archiveBuilder.zipDirectory(Directory(sourcePath),
        filename: '$zipFilePath/out.zip');
  }
}
