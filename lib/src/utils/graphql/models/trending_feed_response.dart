import 'dart:convert';

import 'package:acela/src/global_provider/ipfs_node_provider.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/communicator.dart';

class GraphQlFeedResponse {
  GraphQlFeedResponseData? data;

  GraphQlFeedResponse({
    this.data,
  });

  factory GraphQlFeedResponse.fromRawJson(String str) =>
      GraphQlFeedResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GraphQlFeedResponse.fromJson(Map<String, dynamic> json) =>
      GraphQlFeedResponse(
        data: json["data"] == null
            ? null
            : GraphQlFeedResponseData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
      };
}

class GraphQlFeedResponseData {
  TrendingFeed? trendingFeed;
  TrendingFeed? socialFeed;
  TrendingFeed? relatedFeed;
  TrendingFeed? searchFeed;

  GraphQlFeedResponseData({
    this.trendingFeed,
    this.socialFeed,
    this.relatedFeed,
    this.searchFeed,
  });

  factory GraphQlFeedResponseData.fromRawJson(String str) =>
      GraphQlFeedResponseData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GraphQlFeedResponseData.fromJson(Map<String, dynamic> json) =>
      GraphQlFeedResponseData(
        trendingFeed: json["trendingFeed"] == null
            ? null
            : TrendingFeed.fromJson(json["trendingFeed"]),
        socialFeed: json["socialFeed"] == null
            ? null
            : TrendingFeed.fromJson(json["socialFeed"]),
        relatedFeed: json["relatedFeed"] == null
            ? null
            : TrendingFeed.fromJson(json["relatedFeed"]),
        searchFeed: json["searchFeed"] == null
            ? null
            : TrendingFeed.fromJson(json["searchFeed"]),
      );

  Map<String, dynamic> toJson() => {
        "trendingFeed": trendingFeed?.toJson(),
        "socialFeed": socialFeed?.toJson(),
        "relatedFeed": socialFeed?.toJson(),
        "searchFeed": searchFeed?.toJson(),
      };
}

class TrendingFeed {
  List<GQLFeedItem>? items;

  TrendingFeed({
    this.items,
  });

  factory TrendingFeed.fromRawJson(String str) =>
      TrendingFeed.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TrendingFeed.fromJson(Map<String, dynamic> json) => TrendingFeed(
        items: json["items"] == null
            ? []
            : List<GQLFeedItem>.from(
                json["items"]!.map((x) => GQLFeedItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
      };
}

class GQLFeedItem {
  GQLFeedItemStats? stats;
  Spkvideo? spkvideo;
  final String? playUrl;
  String? permlink;
  String? lang;
  DateTime? createdAt;
  GQLFeedCommunity? community;
  String? title;
  List<String>? tags;
  GQLFeedItemAuthor? author;
  String? body;
  List<GQLFeedItemChild>? children;
  final bool isVideo;

  GQLFeedItem({
    required this.playUrl,
    required this.isVideo,
    this.stats,
    this.spkvideo,
    this.permlink,
    this.lang,
    this.createdAt,
    this.community,
    this.title,
    this.tags,
    this.author,
    this.body,
    this.children,
  });

  factory GQLFeedItem.fromRawJson(String str) =>
      GQLFeedItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GQLFeedItem.fromJson(Map<String, dynamic> json) => GQLFeedItem(
        playUrl: json['json_metadata']?['raw']?['video']?['info']?['video_v2'],
        isVideo: json['json_metadata']?['raw']?['video']?['info']?['video_v2']
                ?.endsWith('.m3u8') ??
            true,
        stats: json["stats"] == null
            ? null
            : GQLFeedItemStats.fromJson(json["stats"]),
        spkvideo: json["spkvideo"] == null
            ? null
            : Spkvideo.fromJson(json["spkvideo"]),
        permlink: json["permlink"],
        lang: json["lang"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        community: json["community"] == null
            ? null
            : GQLFeedCommunity.fromJson(json["community"]),
        title: json["title"],
        tags: json["tags"] == null
            ? []
            : List<String>.from(json["tags"]!.map((x) => x)),
        author: json["author"] == null
            ? null
            : GQLFeedItemAuthor.fromJson(json["author"]),
        body: json["body"],
        children: json["children"] == null
            ? []
            : List<GQLFeedItemChild>.from(
                json["children"]!.map((x) => GQLFeedItemChild.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "stats": stats?.toJson(),
        "spkvideo": spkvideo?.toJson(),
        "permlink": permlink,
        "lang": lang,
        "created_at": createdAt?.toIso8601String(),
        "community": community?.toJson(),
        "title": title,
        "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
        "author": author?.toJson(),
        "body": body,
        "children": children == null
            ? []
            : List<dynamic>.from(children!.map((x) => x.toJson())),
      };

  String get thumbnailValue {
    if ((spkvideo?.thumbnailUrl ?? '').startsWith("http")) {
      return spkvideo!.thumbnailUrl!;
    }
    return '${Communicator.threeSpeakCDN}/ipfs/${(spkvideo?.thumbnailUrl ?? '').replaceAll("ipfs://", '')}';
  }

  String videoV2M3U8(HiveUserData data) {
    if ((spkvideo?.playUrl ?? '').contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmWADpD1PWPnmYVkSZvgokU5vcN2qZqvsHCA985GZ5Jf4r/manifest.m3u8
      var url = (spkvideo?.playUrl ?? '')
          .replaceAll('ipfs://', IpfsNodeProvider().nodeUrl)
          .replaceAll('manifest', '${data.resolution}/index');
      return url;
    }
    return spkvideo?.playUrl ?? '';
  }

  // 480p_video.m3u8
  String mobileEncodedVideoUrl() {
    if ((spkvideo?.playUrl ?? '').contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmWADpD1PWPnmYVkSZvgokU5vcN2qZqvsHCA985GZ5Jf4r/manifest.m3u8
      var url = (spkvideo?.playUrl ?? '')
          .replaceAll('ipfs://', IpfsNodeProvider().nodeUrl)
          .replaceAll('manifest', '480p_video');
      return url;
    }
    return spkvideo?.playUrl ?? '';
  }

  String get hlsUrl {
    if ((spkvideo?.playUrl ?? '').contains('ipfs')) {
      // example
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/manifest.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmTRDJcgtt66pxs3ZnQCdRw57b69NS2TQvF4yHwaux5grT/480p/index.m3u8
      // https://ipfs-3speak.b-cdn.net/ipfs/QmWADpD1PWPnmYVkSZvgokU5vcN2qZqvsHCA985GZ5Jf4r/manifest.m3u8
      var url = (spkvideo?.playUrl ?? '')
          .replaceAll('ipfs://', IpfsNodeProvider().nodeUrl);
      return url;
    }
    return spkvideo?.playUrl ?? '';
  }
}

class GQLFeedItemAuthor {
  String? username;

  GQLFeedItemAuthor({
    this.username,
  });

  factory GQLFeedItemAuthor.fromRawJson(String str) =>
      GQLFeedItemAuthor.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GQLFeedItemAuthor.fromJson(Map<String, dynamic> json) =>
      GQLFeedItemAuthor(
        username: json["username"],
      );

  Map<String, dynamic> toJson() => {
        "username": username,
      };
}

class GQLFeedItemChild {
  GQLFeedItemAuthor? author;
  String? body;
  DateTime? createdAt;
  String? permlink;
  String? title;

  GQLFeedItemChild({
    this.author,
    this.body,
    this.createdAt,
    this.permlink,
    this.title,
  });

  factory GQLFeedItemChild.fromRawJson(String str) =>
      GQLFeedItemChild.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GQLFeedItemChild.fromJson(Map<String, dynamic> json) =>
      GQLFeedItemChild(
        author: json["author"] == null
            ? null
            : GQLFeedItemAuthor.fromJson(json["author"]),
        body: json["body"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        permlink: json["permlink"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "author": author?.toJson(),
        "body": body,
        "created_at": createdAt?.toIso8601String(),
        "permlink": permlink,
        "title": title,
      };
}

class GQLFeedCommunity {
  String? id;
  String? about;
  bool? needsUpdate;
  String? title;
  CommunityImages? images;
  List<dynamic>? topics;
  String? username;
  DateTime? createdAt;
  String? description;
  String? flagText;
  bool? isNsfw;
  String? lang;
  List<List<String>>? roles;
  int? subscribers;

  GQLFeedCommunity({
    this.id,
    this.about,
    this.needsUpdate,
    this.title,
    this.images,
    this.topics,
    this.username,
    this.createdAt,
    this.description,
    this.flagText,
    this.isNsfw,
    this.lang,
    this.roles,
    this.subscribers,
  });

  factory GQLFeedCommunity.fromRawJson(String str) =>
      GQLFeedCommunity.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GQLFeedCommunity.fromJson(Map<String, dynamic> json) =>
      GQLFeedCommunity(
        id: json["_id"],
        about: json["about"],
        needsUpdate: json["needs_update"],
        title: json["title"],
        images: json["images"] == null
            ? null
            : CommunityImages.fromJson(json["images"]),
        topics: json["topics"] == null
            ? []
            : List<dynamic>.from(json["topics"]!.map((x) => x)),
        username: json["username"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        description: json["description"],
        flagText: json["flag_text"],
        isNsfw: json["is_nsfw"],
        lang: json["lang"],
        roles: json["roles"] == null
            ? []
            : List<List<String>>.from(
                json["roles"]!.map((x) => List<String>.from(x.map((x) => x)))),
        subscribers: json["subscribers"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "about": about,
        "needs_update": needsUpdate,
        "title": title,
        "images": images?.toJson(),
        "topics":
            topics == null ? [] : List<dynamic>.from(topics!.map((x) => x)),
        "username": username,
        "created_at": createdAt?.toIso8601String(),
        "description": description,
        "flag_text": flagText,
        "is_nsfw": isNsfw,
        "lang": lang,
        "roles": roles == null
            ? []
            : List<dynamic>.from(
                roles!.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "subscribers": subscribers,
      };
}

class CommunityImages {
  String? avatar;
  String? cover;

  CommunityImages({
    this.avatar,
    this.cover,
  });

  factory CommunityImages.fromRawJson(String str) =>
      CommunityImages.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CommunityImages.fromJson(Map<String, dynamic> json) =>
      CommunityImages(
        avatar: json["avatar"],
        cover: json["cover"],
      );

  Map<String, dynamic> toJson() => {
        "avatar": avatar,
        "cover": cover,
      };
}

class Spkvideo {
  String? thumbnailUrl;
  String? playUrl;
  double? duration;
  bool? isShort;
  String? body;
  int? height;
  int? width;

  Spkvideo(
      {this.thumbnailUrl,
      this.playUrl,
      this.duration,
      this.isShort,
      this.body,
      this.height,
      this.width});

  factory Spkvideo.fromRawJson(String str) =>
      Spkvideo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Spkvideo.fromJson(Map<String, dynamic> json) => Spkvideo(
        thumbnailUrl: json["thumbnail_url"],
        playUrl: json["play_url"],
        duration: json["duration"]?.toDouble(),
        isShort: json["is_short"],
        body: json["body"],
        height: json["height"],
        width: json["width"],
      );

  Map<String, dynamic> toJson() => {
        "thumbnail_url": thumbnailUrl,
        "play_url": playUrl,
        "duration": duration,
        "is_short": isShort,
        "body": body,
        "width": width,
        "height": height,
      };
}

class GQLFeedItemStats {
  double? totalHiveReward;
  int? numVotes;
  int? numComments;

  GQLFeedItemStats({
    this.totalHiveReward,
    this.numVotes,
    this.numComments,
  });

  factory GQLFeedItemStats.fromRawJson(String str) =>
      GQLFeedItemStats.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory GQLFeedItemStats.fromJson(Map<String, dynamic> json) =>
      GQLFeedItemStats(
        totalHiveReward: json["total_hive_reward"]?.toDouble(),
        numVotes: json["num_votes"],
        numComments: json["num_comments"],
      );

  Map<String, dynamic> toJson() => {
        "total_hive_reward": totalHiveReward,
        "num_votes": numVotes,
        "num_comments": numComments,
      };
}

class VideoDetailsFeed {
  final GQLFeedItem item;

  VideoDetailsFeed({required this.item});

  factory VideoDetailsFeed.fromRawJson(String str) =>
      VideoDetailsFeed.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VideoDetailsFeed.fromJson(Map<String, dynamic> json) =>
      VideoDetailsFeed(
        item: GQLFeedItem.fromJson(json['data']['socialPost']),
      );

  Map<String, dynamic> toJson() => {"item": item.toJson()};
}
