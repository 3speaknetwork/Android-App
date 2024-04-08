import 'dart:convert';

import 'package:equatable/equatable.dart';

class CommentResponseModel {
  final String? jsonrpc;
  final List<CommentItemModel> comments;
  final int? id;

  CommentResponseModel({
    this.jsonrpc,
    this.comments = const [],
    this.id,
  });

  factory CommentResponseModel.fromRawJson(String str) =>
      CommentResponseModel.fromJson(json.decode(str));

  factory CommentResponseModel.fromJson(Map<String, dynamic> json) =>
      CommentResponseModel(
        jsonrpc: json["jsonrpc"],
        comments: _parseComments(json["result"]),
        id: json["id"],
      );

  static List<CommentItemModel> _parseComments(Map<String, dynamic>? json) {
    List<CommentItemModel> items = [];
    if (json != null) {
      int count = 0;
      json.forEach((key, value) {
        if (count != 0) {
          items.add(CommentItemModel.fromJson(value));
        }
        count++;
      });
      ;
    }
    return items;
  }
}

// ignore: must_be_immutable
class CommentItemModel extends Equatable {
  final int? postId;
  final String author;
  final String permlink;
  final String? category;
  final String? title;
  final String body;
  final CommentMetaDataModel? jsonMetadata;
  final DateTime created;
  final DateTime? updated;
  final int depth;
  final int children;
  final int? netRshares;
  final bool? isPaidout;
  final DateTime? payoutAt;
  final double? payout;
  final String? pendingPayoutValue;
  final String? authorPayoutValue;
  final String? curatorPayoutValue;
  final String? promoted;
  final List<String> replies;
  final int? reblogs;
  final double? authorReputation;
  final Stats? stats;
  final String? url;
  final List<dynamic>? beneficiaries;
  final String? maxAcceptedPayout;
  final int? percentHbd;
  final String? parentAuthor;
  final String? parentPermlink;
  final List<CommentActiveVote> activeVotes;
  final List<dynamic> blacklists;
  final String? community;
  final String? communityTitle;
  final String? authorRole;
  final String? authorTitle;
  var visited = false;
  final bool isLocallyAdded;

  CommentItemModel(
      {this.postId,
      required this.author,
      required this.permlink,
      this.category,
      this.title,
      required this.body,
      this.jsonMetadata,
      required this.created,
      this.updated,
      required this.depth,
      required this.children,
      this.netRshares,
      this.isPaidout,
      this.payoutAt,
      this.payout,
      this.pendingPayoutValue,
      this.authorPayoutValue,
      this.curatorPayoutValue,
      this.promoted,
      this.replies = const [],
      this.reblogs,
      this.authorReputation,
      this.stats,
      this.url,
      this.beneficiaries,
      this.maxAcceptedPayout,
      this.percentHbd,
      this.parentAuthor,
      this.parentPermlink,
      this.activeVotes = const [],
      this.blacklists = const [],
      this.community,
      this.communityTitle,
      this.authorRole,
      this.authorTitle,
      this.isLocallyAdded = false});

  CommentItemModel copyWith({
    int? postId,
    String? author,
    String? permlink,
    String? category,
    String? title,
    String? body,
    CommentMetaDataModel? jsonMetadata,
    DateTime? created,
    DateTime? updated,
    int? depth,
    int? children,
    int? netRshares,
    bool? isPaidout,
    DateTime? payoutAt,
    double? payout,
    String? pendingPayoutValue,
    String? authorPayoutValue,
    String? curatorPayoutValue,
    String? promoted,
    List<String>? replies,
    int? reblogs,
    double? authorReputation,
    Stats? stats,
    String? url,
    List<dynamic>? beneficiaries,
    String? maxAcceptedPayout,
    int? percentHbd,
    String? parentAuthor,
    String? parentPermlink,
    List<CommentActiveVote>? activeVotes,
    List<dynamic>? blacklists,
    String? community,
    String? communityTitle,
    String? authorRole,
    String? authorTitle,
  }) {
    return CommentItemModel(
      postId: postId ?? this.postId,
      author: author ?? this.author,
      permlink: permlink ?? this.permlink,
      category: category ?? this.category,
      title: title ?? this.title,
      body: body ?? this.body,
      jsonMetadata: jsonMetadata ?? this.jsonMetadata,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      depth: depth ?? this.depth,
      children: children ?? this.children,
      netRshares: netRshares ?? this.netRshares,
      isPaidout: isPaidout ?? this.isPaidout,
      payoutAt: payoutAt ?? this.payoutAt,
      payout: payout ?? this.payout,
      pendingPayoutValue: pendingPayoutValue ?? this.pendingPayoutValue,
      authorPayoutValue: authorPayoutValue ?? this.authorPayoutValue,
      curatorPayoutValue: curatorPayoutValue ?? this.curatorPayoutValue,
      promoted: promoted ?? this.promoted,
      replies: replies ?? this.replies,
      reblogs: reblogs ?? this.reblogs,
      authorReputation: authorReputation ?? this.authorReputation,
      stats: stats ?? this.stats,
      url: url ?? this.url,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      maxAcceptedPayout: maxAcceptedPayout ?? this.maxAcceptedPayout,
      percentHbd: percentHbd ?? this.percentHbd,
      parentAuthor: parentAuthor ?? this.parentAuthor,
      parentPermlink: parentPermlink ?? this.parentPermlink,
      activeVotes: activeVotes ?? this.activeVotes,
      blacklists: blacklists ?? this.blacklists,
      community: community ?? this.community,
      communityTitle: communityTitle ?? this.communityTitle,
      authorRole: authorRole ?? this.authorRole,
      authorTitle: authorTitle ?? this.authorTitle,
    );
  }

  factory CommentItemModel.fromRawJson(String str) =>
      CommentItemModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CommentItemModel.fromJson(Map<String, dynamic> json) =>
      CommentItemModel(
        postId: json["post_id"],
        author: json["author"],
        permlink: json["permlink"],
        category: json["category"],
        title: json["title"],
        body: json["body"],
        jsonMetadata: json["json_metadata"] == null
            ? null
            : CommentMetaDataModel.fromJson(json["json_metadata"]),
        created: DateTime.parse(json["created"]),
        updated:
            json["updated"] == null ? null : DateTime.parse(json["updated"]),
        depth: json["depth"],
        children: json["children"],
        netRshares: json["net_rshares"],
        isPaidout: json["is_paidout"],
        payoutAt: json["payout_at"] == null
            ? null
            : DateTime.parse(json["payout_at"]),
        payout: json["payout"]?.toDouble(),
        pendingPayoutValue: json["pending_payout_value"],
        authorPayoutValue: json["author_payout_value"],
        curatorPayoutValue: json["curator_payout_value"],
        promoted: json["promoted"],
        replies: json["replies"] == null
            ? []
            : List<String>.from(json["replies"]!.map((x) => x)),
        reblogs: json["reblogs"],
        authorReputation: json["author_reputation"]?.toDouble(),
        stats: json["stats"] == null ? null : Stats.fromJson(json["stats"]),
        url: json["url"],
        beneficiaries: json["beneficiaries"] == null
            ? []
            : List<dynamic>.from(json["beneficiaries"]!.map((x) => x)),
        maxAcceptedPayout: json["max_accepted_payout"],
        percentHbd: json["percent_hbd"],
        parentAuthor: json["parent_author"],
        parentPermlink: json["parent_permlink"],
        activeVotes: json["active_votes"] == null
            ? []
            : List<CommentActiveVote>.from(json["active_votes"]!
                .map((x) => CommentActiveVote.fromJson(x))),
        blacklists: json["blacklists"] == null
            ? []
            : List<dynamic>.from(json["blacklists"]!.map((x) => x)),
        community: json["community"],
        communityTitle: json["community_title"],
        authorRole: json["author_role"],
        authorTitle: json["author_title"],
      );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "author": author,
        "permlink": permlink,
        "category": category,
        "title": title,
        "body": body,
        "json_metadata": jsonMetadata?.toJson(),
        "created": created.toIso8601String(),
        "updated": updated?.toIso8601String(),
        "depth": depth,
        "children": children,
        "net_rshares": netRshares,
        "is_paidout": isPaidout,
        "payout_at": payoutAt?.toIso8601String(),
        "payout": payout,
        "pending_payout_value": pendingPayoutValue,
        "author_payout_value": authorPayoutValue,
        "curator_payout_value": curatorPayoutValue,
        "promoted": promoted,
        "replies": List<dynamic>.from(replies.map((x) => x)),
        "reblogs": reblogs,
        "author_reputation": authorReputation,
        "stats": stats?.toJson(),
        "url": url,
        "beneficiaries": beneficiaries == null
            ? []
            : List<dynamic>.from(beneficiaries!.map((x) => x)),
        "max_accepted_payout": maxAcceptedPayout,
        "percent_hbd": percentHbd,
        "parent_author": parentAuthor,
        "parent_permlink": parentPermlink,
        "active_votes": List<dynamic>.from(activeVotes!.map((x) => x.toJson())),
        "blacklists": List<dynamic>.from(blacklists!.map((x) => x)),
        "community": community,
        "community_title": communityTitle,
        "author_role": authorRole,
        "author_title": authorTitle,
      };

  @override
  List<Object?> get props =>
      [postId, permlink, author, parentPermlink, parentAuthor, created];
}

class CommentActiveVote extends Equatable {
  final int? rshares;
  final String? voter;

  CommentActiveVote({
    this.rshares,
    this.voter,
  });

  factory CommentActiveVote.fromRawJson(String str) =>
      CommentActiveVote.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CommentActiveVote.fromJson(Map<String, dynamic> json) =>
      CommentActiveVote(
        rshares: json["rshares"],
        voter: json["voter"],
      );

  Map<String, dynamic> toJson() => {
        "rshares": rshares,
        "voter": voter,
      };

  @override
  List<Object?> get props => [voter];
}

class CommentMetaDataModel {
  final List<String>? tags;
  final String? app;

  CommentMetaDataModel({
    this.tags,
    this.app,
  });

  factory CommentMetaDataModel.fromRawJson(String str) =>
      CommentMetaDataModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CommentMetaDataModel.fromJson(Map<String, dynamic> json) =>
      CommentMetaDataModel(
        tags: json["tags"] == null
            ? []
            : json['tags'] is String ? [json['tags']] : List<String>.from(json["tags"]!.map((x) => x)),
        app: json["app"],
      );

  Map<String, dynamic> toJson() => {
        "tags": tags == null ? [] : List<dynamic>.from(tags!.map((x) => x)),
        "app": app,
      };
}

class Stats {
  final bool? hide;
  final bool? gray;
  final int? totalVotes;
  final double? flagWeight;

  Stats({
    this.hide,
    this.gray,
    this.totalVotes,
    this.flagWeight,
  });

  Stats copyWith({
    bool? hide,
    bool? gray,
    int? totalVotes,
    double? flagWeight,
  }) {
    return Stats(
      hide: hide ?? this.hide,
      gray: gray ?? this.gray,
      totalVotes: totalVotes ?? this.totalVotes,
      flagWeight: flagWeight ?? this.flagWeight,
    );
  }

  factory Stats.fromRawJson(String str) => Stats.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        hide: json["hide"],
        gray: json["gray"],
        totalVotes: json["total_votes"],
        flagWeight: json["flag_weight"],
      );

  Map<String, dynamic> toJson() => {
        "hide": hide,
        "gray": gray,
        "total_votes": totalVotes,
        "flag_weight": flagWeight,
      };
}
