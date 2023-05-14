import 'dart:convert';

class VideoUploadCompleteRequest {
  final String videoId;
  final String title;
  final String description;
  final bool isNsfwContent;
  final String tags;
  final String? thumbnail;
  final bool rewardPowerup;
  final bool declineRewards;
  final String beneficiaries;

  VideoUploadCompleteRequest({
    required this.videoId,
    required this.title,
    required this.description,
    required this.isNsfwContent,
    required this.tags,
    required this.thumbnail,
    required this.rewardPowerup,
    required this.declineRewards,
    required this.beneficiaries
  });

  Map<String, dynamic> toJson() {
    var map = {
      'videoId': videoId,
      'title': title,
      'description': description,
      'isNsfwContent': isNsfwContent,
      'tags': tags,
      'rewardPowerup': rewardPowerup,
      'declineRewards': declineRewards,
      'beneficiaries': beneficiaries,
    };
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      map['thumbnail'] = thumbnail!;
    }
    return map;
  }

  String toJsonString() => json.encode(toJson());
}

class VideoThumbUpdateRequest {
  final String videoId;
  final String thumbnail;

  VideoThumbUpdateRequest({
    required this.videoId,
    required this.thumbnail,
  });

  Map<String, dynamic> toJson() {
    return {'videoId': videoId, 'thumbnail': thumbnail};
  }

  String toJsonString() => json.encode(toJson());
}

class NewVideoUploadCompleteRequest {
  final String oFilename;
  final int duration;
  final double size;
  final String filename;
  final String thumbnail;
  final String owner;
  final bool isReel;

  NewVideoUploadCompleteRequest({
    required this.oFilename,
    required this.duration,
    required this.size,
    required this.filename,
    required this.thumbnail,
    required this.owner,
    required this.isReel,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'oFilename': oFilename,
        'size': size,
        'duration': duration,
        'thumbnail': thumbnail,
        'owner': owner,
        'isReel': isReel,
      };

  String toJsonString() => json.encode(toJson());
}
