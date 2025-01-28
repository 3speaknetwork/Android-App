import 'dart:convert';

import 'package:acela/src/models/my_account/video_ops.dart';

class VideoDeviceEncodeUploadModel {
  final String originalFilename;
  final int duration;
  final int size; 
  final int width; 
  final int height; 
  final String owner; 
  final String title; 
  final String description;
  final bool isReel; 
  final bool isNsfwContent;
  final String tags; 
  final String communityID; 
  final List<BeneficiariesJson> beneficiaries;
  final bool rewardPowerup; 
  final String tusId; 
  final bool publishLater;

  VideoDeviceEncodeUploadModel({
    required this.originalFilename,
    required this.duration,
    required this.size,
    required this.width,
    required this.height,
    required this.owner,
    required this.title,
    required this.description,
    required this.isReel,
    required this.isNsfwContent,
    required this.tags,
    required this.communityID,
    required this.beneficiaries,
    required this.rewardPowerup,
    required this.tusId,
    required this.publishLater
  });

   VideoDeviceEncodeUploadModel copyWith({
    String? originalFilename,
    int? duration,
    int? size,
    int? width,
    int? height,
    String? owner,
    String? title,
    String? description,
    bool? isReel,
    bool? isNsfwContent,
    String? tags,
    String? communityID,
    List<BeneficiariesJson>? beneficiaries,
    bool? rewardPowerup,
    String? tusId,
    bool? publishLater
  }) {
    return VideoDeviceEncodeUploadModel(
      originalFilename: originalFilename ?? this.originalFilename,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      owner: owner ?? this.owner,
      title: title ?? this.title,
      description: description ?? this.description,
      isReel: isReel ?? this.isReel,
      isNsfwContent: isNsfwContent ?? this.isNsfwContent,
      tags: tags ?? this.tags,
      communityID: communityID ?? this.communityID,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      rewardPowerup: rewardPowerup ?? this.rewardPowerup,
      tusId: tusId ?? this.tusId,
      publishLater: publishLater ?? this.publishLater
    );
  }

  Map<String, dynamic> toJson() {
     var bene = beneficiaries
        .map((e) => e.copyWith(account: e.account.toLowerCase()))
        .toList()
      ..sort(
          (a, b) => a.account.toLowerCase().compareTo(b.account.toLowerCase()));
    return {
      'originalFilename': originalFilename,
      'duration': duration,
      'size': size,
      'width': width,
      'height': height,
      'owner': owner,
      'title': title,
      'description': description,
      'isReel': isReel,
      'isNsfwContent': isNsfwContent,
      'tags': tags,
      'communityID': communityID,
      'beneficiaries': json.encode(bene.map((e) => e.toJson()).toList()),
      'rewardPowerup': rewardPowerup,
      'tusId': tusId,
      'publishLater': publishLater
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
