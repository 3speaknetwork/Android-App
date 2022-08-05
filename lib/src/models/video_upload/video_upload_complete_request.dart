import 'dart:convert';

class VideoUploadCompleteRequest {
  final String videoId;
  final String filename;
  final String title;
  final String description;
  final bool isNsfwContent;
  final String tags;
  final String thumbnail;

  VideoUploadCompleteRequest({
    required this.videoId,
    required this.filename,
    required this.title,
    required this.description,
    required this.isNsfwContent,
    required this.tags,
    required this.thumbnail,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'filename': filename,
        'title': title,
        'description': description,
        'isNsfwContent': isNsfwContent,
        'tags': tags,
        'thumbnail': thumbnail
      };

  String toJsonString() => json.encode(toJson());
}

class NewVideoUploadCompleteRequest {
  final String oFilename;
  final int duration;
  final double size;
  final String filename;
  final String thumbnail;
  final String owner;

  NewVideoUploadCompleteRequest({
    required this.oFilename,
    required this.duration,
    required this.size,
    required this.filename,
    required this.thumbnail,
    required this.owner,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'oFilename': oFilename,
        'size': size,
        'duration': duration,
        'thumbnail': thumbnail,
        'owner': owner,
      };

  String toJsonString() => json.encode(toJson());
}
