import 'dart:convert';

import 'package:acela/src/utils/safe_convert.dart';
import 'package:equatable/equatable.dart';

class HivePostInfo {
  final String jsonrpc;
  final HivePostInfoResult result;
  final int id;

  HivePostInfo({
    this.jsonrpc = "",
    required this.result,
    this.id = 0,
  });

  factory HivePostInfo.fromJson(Map<String, dynamic>? json) => HivePostInfo(
        jsonrpc: asString(json, 'jsonrpc'),
        result: HivePostInfoResult.fromJson(asMap(json, 'result')),
        id: asInt(json, 'id'),
      );

  factory HivePostInfo.fromJsonString(String jsonString) =>
      HivePostInfo.fromJson(json.decode(jsonString));
}

class HivePostInfoResult {
  final List<HivePostInfoPostResultBody> resultData;

  HivePostInfoResult({
    required this.resultData,
  });

  factory HivePostInfoResult.fromJson(Map<String, dynamic>? json) {
    var result = json?.keys.map((e) => HivePostInfoPostResultBody.fromJson(
            json[e] as Map<String, dynamic>)) ??
        [];
    return HivePostInfoResult(resultData: result.toList());
  }
}

class HivePostInfoPostResultBody {
  final double payout;
  final List<ActiveVotesItem> activeVotes;
  final String permlink;

  HivePostInfoPostResultBody({
    required this.payout,
    required this.activeVotes,
    required this.permlink,
  });

  HivePostInfoPostResultBody copyWith({
    double? payout,
    List<ActiveVotesItem>? activeVotes,
    String? permlink,
  }) {
    return HivePostInfoPostResultBody(
      payout: payout ?? this.payout,
      activeVotes: activeVotes ?? this.activeVotes,
      permlink: permlink ?? this.permlink,
    );
  }

  factory HivePostInfoPostResultBody.fromJson(Map<String, dynamic>? json) =>
      HivePostInfoPostResultBody(
        payout: asDouble(json, 'payout'),
        permlink: asString(json, 'permlink'),
        activeVotes: asList(json, 'active_votes')
            .map((e) => ActiveVotesItem.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'payout': payout,
        'permlink': permlink,
        'active_votes': activeVotes.map((e) => e.toJson()),
      };
}

class ActiveVotesItem extends Equatable {
  final int rshares;
  final String voter;

  const ActiveVotesItem({
    this.rshares = 0,
    this.voter = "",
  });

  factory ActiveVotesItem.fromJson(Map<String, dynamic>? json) =>
      ActiveVotesItem(
        rshares: asInt(json, 'rshares'),
        voter: asString(json, 'voter'),
      );
      
  Map<String, dynamic> toJson() => {
        'rshares': rshares,
        'voter': voter,
      };

  @override
  List<Object?> get props => [voter];
}
