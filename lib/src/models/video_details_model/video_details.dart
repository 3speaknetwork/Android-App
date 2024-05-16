import 'dart:convert';
import 'dart:developer';
import 'package:acela/src/global_provider/ipfs_node_provider.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/safe_convert.dart';
import 'package:collection/collection.dart';

List<VideoDetails> videoItemsFromString(String string) {
  final jsonList = json.decode(string) as List;
  final list = jsonList.map((e) => VideoDetails.fromJson(e)).toList();
  return list;
}

class VideoDetails {
  final String created;
  final bool paid;
  final int views;
  final List<String> tagsV2;
  final String id;
  final String community;
  final String owner;
  final bool steemPosted;
  final String status;
  final String playUrl;
  final String language;
  final int? encodingProgress;
  final String thumbnail;

  final String video_v2;
  final String description;
  final String title;
  final String tags;
  final String permlink;
  final double duration;
  final int size;
  final String originalFilename;
  final bool firstUpload;
  final String beneficiaries;
  final String visible_status;

  String getThumbnail() {
    return thumbnail.replaceAll('ipfs://', IpfsNodeProvider().nodeUrl);
  }

  String getVideoUrl(HiveUserData data) {
    if (playUrl.contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      return playUrl.replaceAll('manifest', '${data.resolution}/index');
    } else {
      // example
      // https://threespeakvideo.b-cdn.net/chjwguvd/default.m3u8
      // https://threespeakvideo.b-cdn.net/chjwguvd/480p.m3u8
      return playUrl.replaceAll('default', '${data.resolution}');
    }
  }

  String rootVideoV2M3U8() {
    if (video_v2.contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmWADpD1PWPnmYVkSZvgokU5vcN2qZqvsHCA985GZ5Jf4r/manifest.m3u8
      var url = video_v2.replaceAll('ipfs://', IpfsNodeProvider().nodeUrl);
      log('Root Play url is - $url');
      return url;
    }
    return video_v2;
  }

  String videoV2M3U8(HiveUserData data) {
    if (video_v2.contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmWADpD1PWPnmYVkSZvgokU5vcN2qZqvsHCA985GZ5Jf4r/manifest.m3u8
      var url = video_v2
          .replaceAll('ipfs://', IpfsNodeProvider().nodeUrl)
          .replaceAll('manifest', '${data.resolution}/index');
      log('Play url is - $url');
      return url;
    }
    return video_v2;
  }

  String get thumbnailValue {
    if (thumbnail.startsWith("http")) {
      return thumbnail;
    }
    return '${Communicator.threeSpeakCDN}/ipfs/${thumbnail.replaceAll("ipfs://", '')}';
  }

  String get videoValue {
    if (video_v2.startsWith("http")) {
      return thumbnail;
    }
    return '${Communicator.threeSpeakCDN}/ipfs/${video_v2.replaceAll("ipfs://", '')}';
  }

  VideoDetails({
    this.created = "",
    this.paid = false,
    this.views = 0,
    required this.tagsV2,
    this.id = "",
    this.community = "",
    this.permlink = "",
    this.duration = 0.0,
    this.size = 0,
    this.owner = "",
    this.description = "",
    this.thumbnail = "",
    this.title = "",
    this.language = "",
    this.playUrl = "",
    this.steemPosted = false,
    this.status = "",
    required this.encodingProgress,
    required this.video_v2,
    required this.tags,
    required this.originalFilename,
    required this.firstUpload,
    required this.beneficiaries,
    required this.visible_status,
  });

  factory VideoDetails.fromJsonString(String jsonString) =>
      VideoDetails.fromJson(json.decode(jsonString));

  List<BeneficiariesJson> get benes {
    if (beneficiaries == "[]") {
      return [
        BeneficiariesJson(account: 'sagarkothari88', src: 'mobile', weight: 1),
        BeneficiariesJson(
            account: 'spk.beneficiary', src: 'threespeak', weight: 9),
        BeneficiariesJson(
            account: 'threespeakleader', src: 'threespeak', weight: 1),
      ];
    } else {
      try {
        var array = BeneficiariesJson.fromJsonString(beneficiaries);
        List<BeneficiariesJson> beneficiariesToSet = [];
        for (var item in array) {
          var name = item.account;
          var weight = item.weight;
          if ((weight / 100) >= 1 ) {
            beneficiariesToSet.add(
              BeneficiariesJson(
                account: name,
                weight: weight ~/ 100,
                src: item.src,
              ),
            );
          }
        }
        return beneficiariesToSet;
      } catch (e) {
        return [
          BeneficiariesJson(
              account: 'sagarkothari88', src: 'mobile', weight: 1),
          BeneficiariesJson(
              account: 'spk.beneficiary', src: 'threespeak', weight: 9),
          BeneficiariesJson(
              account: 'threespeakleader', src: 'threespeak', weight: 1),
        ];
      }
    }
  }

  factory VideoDetails.fromJson(Map<String, dynamic>? json) => VideoDetails(
        created: asString(json, 'created'),
        paid: asBool(json, 'paid'),
        views: asInt(json, 'views'),
        tagsV2: asList(json, 'tags_v2').map((e) => e.toString()).toList(),
        id: asString(json, '_id'),
        encodingProgress: json!=null ? asInt(json, 'encodingProgress') : null,
        community: asString(json, 'community'),
        permlink: asString(json, 'permlink'),
        duration: asDouble(json, 'duration'),
        size: asInt(json, 'size'),
        owner: asString(json, 'owner'),
        description: asString(json, 'description'),
        thumbnail: asString(json, 'thumbnail'),
        title: asString(json, 'title'),
        language: asString(json, 'language'),
        playUrl: asString(json, 'playUrl'),
        steemPosted: asBool(json, 'steemPosted'),
        status: asString(json, 'status'),
        tags: asString(json, 'tags'),
        video_v2: asString(json, 'video_v2'),
        originalFilename: asString(json, 'originalFilename'),
        firstUpload: asBool(json, 'firstUpload'),
        beneficiaries: asString(json, 'beneficiaries'),
        visible_status: asString(json, 'visible_status'),
      );

  String toJsonString() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'created': created,
        'paid': paid,
        'views': views,
        'tags_v2': tagsV2.map((e) => e),
        '_id': id,
        'community': community,
        'permlink': permlink,
        'duration': duration,
        'size': size,
        'owner': owner,
        'description': description,
        'thumbnail': thumbnail,
        'title': title,
        'language': language,
        'playUrl': playUrl,
        'steemPosted': steemPosted,
        'status': status,
      };
}
