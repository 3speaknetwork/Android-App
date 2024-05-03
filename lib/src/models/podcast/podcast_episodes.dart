import 'dart:convert';

import 'package:dart_rss/dart_rss.dart';

class PodcastEpisodesByFeedResponse {
  String? status;
  List<dynamic>? liveItems;
  List<PodcastEpisode>? items;
  int? count;
  String? query;
  String? description;

  PodcastEpisodesByFeedResponse({
    this.status,
    this.liveItems,
    this.items,
    this.count,
    this.query,
    this.description,
  });

  factory PodcastEpisodesByFeedResponse.fromRawJson(String str) =>
      PodcastEpisodesByFeedResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PodcastEpisodesByFeedResponse.fromJson(Map<String, dynamic> json) =>
      PodcastEpisodesByFeedResponse(
        status: json["status"],
        liveItems: json["liveItems"] == null
            ? []
            : List<dynamic>.from(json["liveItems"]!.map((x) => x)),
        items: json["items"] == null
            ? []
            : List<PodcastEpisode>.from(
                json["items"]!.map((x) => PodcastEpisode.fromJson(x))),
        count: json["count"],
        query: json["query"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "liveItems": liveItems == null
            ? []
            : List<dynamic>.from(liveItems!.map((x) => x)),
        "items": items == null
            ? []
            : List<dynamic>.from(items!.map((x) => x.toJson())),
        "count": count,
        "query": query,
        "description": description,
      };
}

class PodcastEpisode {
  String? id;
  String? title;
  String? link;
  String? description;
  int? datePublished;
  String? datePublishedPretty;
  String? enclosureUrl;
  int? duration;
  int? episode;
  String? image;
  String? feedImage;
  String? guid;
  String? chaptersUrl;
  bool isAudio;

  PodcastEpisode(
      {this.id,
      this.title,
      this.link,
      this.description,
      this.datePublished,
      this.datePublishedPretty,
      this.enclosureUrl,
      this.duration,
      this.episode,
      this.image,
      this.feedImage,
      this.guid,
      this.chaptersUrl,
      required this.isAudio});

  factory PodcastEpisode.fromRawJson(String str) =>
      PodcastEpisode.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  String? get networkImage {
    if (image != null && image!.isNotEmpty) {
      return image;
    }
    if (feedImage != null && feedImage!.isNotEmpty) {
      return feedImage;
    }
    return null;
  }

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) => PodcastEpisode(
      id: json["id"].toString(),
      isAudio:
          json['isAudio'] ?? json['enclosureType']?.contains('audio') ?? true,
      title: json["title"],
      link: json["link"],
      description: json["description"],
      datePublished: json["datePublished"],
      datePublishedPretty: json["datePublishedPretty"],
      enclosureUrl: json["enclosureUrl"],
      duration: json["duration"],
      episode: json["episode"],
      image: json["image"],
      feedImage : json["feedImage"],
      guid: json["guid"],
      chaptersUrl: json['chaptersUrl']);

  factory PodcastEpisode.fromRss(RssItem rssItem) => PodcastEpisode(
        id: rssItem.guid,
        isAudio: rssItem.enclosure?.type?.contains('audio') ?? true,
        title: rssItem.title,
        link: rssItem.link,
        description: rssItem.description,
        datePublished: null,
        datePublishedPretty: rssItem.pubDate,
        enclosureUrl: rssItem.enclosure?.url,
        duration: rssItem.itunes?.duration?.inSeconds,
        episode: rssItem.itunes?.episode,
        image: rssItem.itunes?.image?.href,
        guid: rssItem.guid,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "link": link,
        "description": description,
        "datePublished": datePublished,
        "datePublishedPretty": datePublishedPretty,
        "enclosureUrl": enclosureUrl,
        "duration": duration,
        "episode": episode,
        "image": image,
        'chaptersUrl': chaptersUrl,
        'isAudio': isAudio
      };

  PodcastEpisode copyWith({
    String? id,
    String? title,
    String? link,
    String? description,
    int? datePublished,
    String? datePublishedPretty,
    String? enclosureUrl,
    int? duration,
    int? episode,
    String? image,
    String? guid,
    String? chaptersUrl,
    bool? isAudio,
  }) {
    return PodcastEpisode(
      id: id ?? this.id,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      datePublished: datePublished ?? this.datePublished,
      datePublishedPretty: datePublishedPretty ?? this.datePublishedPretty,
      enclosureUrl: enclosureUrl ?? this.enclosureUrl,
      duration: duration ?? this.duration,
      episode: episode ?? this.episode,
      image: image ?? this.image,
      guid: guid ?? this.guid,
      chaptersUrl: chaptersUrl ?? this.chaptersUrl,
      isAudio: isAudio ?? this.isAudio,
    );
  }
}
