import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/models/hive_comments/new_hive_comment/new_hive_comment.dart';
import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/models/trending_tags/trending_tags_response.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class GQLCommunicator {
  static const defaultGQLServer = "union.us-02.infra.3speak.tv";
  // static const gqlServer = "https://union.us-02.infra.3speak.tv/api/v2/graphql";
  static const dataQuery =
      "{\n    items {\n      created_at\n      title\n      ... on HivePost {\n        permlink\n        lang\n        title\n        tags\n        spkvideo\n        stats {\n          num_comments\n          num_votes\n          total_hive_reward\n        }\n        author {\n          username\n        }\n json_metadata {\n          raw\n        }\n      }\n    }\n  }\n}";

  Future<List<GQLFeedItem>> getGQLFeed(String operation, String query) async {
    const storage = FlutterSecureStorage();
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    String gqlServer = "https://$union/api/v2/graphql";
    var headers = {
      'Connection': 'keep-alive',
      'content-type': 'application/json',
    };
    var request = http.Request('POST', Uri.parse(gqlServer));
    request.body = json
        .encode({"query": query, "operationName": operation, "extensions": {}});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var responseData = GraphQlFeedResponse.fromRawJson(string);
      List<GQLFeedItem> items = [];
      if ((responseData.data?.trendingFeed?.items ?? []).isNotEmpty) {
        items = responseData.data?.trendingFeed?.items ?? [];
      } else if ((responseData.data?.socialFeed?.items ?? []).isNotEmpty) {
        items = responseData.data?.socialFeed?.items ?? [];
      } else if ((responseData.data?.relatedFeed?.items ?? []).isNotEmpty) {
        items = responseData.data?.relatedFeed?.items ?? [];
      } else if ((responseData.data?.searchFeed?.items ?? []).isNotEmpty) {
        items = responseData.data?.searchFeed?.items ?? [];
      }
      return items.where((element) => element.spkvideo != null).toList();
    } else {
      print(response.reasonPhrase);
      throw response.reasonPhrase ?? 'Error occurred';
    }
  }

  Future<TrendingTagResponse> getTrendingTags() async {
    var headers = {
      'Connection': 'keep-alive',
      'content-type': 'application/json',
    };
    const storage = FlutterSecureStorage();
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    String gqlServer = "https://$union/api/v2/graphql";
    var request = http.Request('POST', Uri.parse(gqlServer));
    var query =
        "query TrendingTags {\n  trendingTags(limit: 50) {\n    tags {\n      score\n      tag\n    }\n  }\n}";
    request.body = json.encode(
        {"query": query, "operationName": "TrendingTags", "extensions": {}});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      return TrendingTagResponse.fromRawJson(string);
    } else {
      print(response.reasonPhrase);
      throw response.reasonPhrase ?? 'Error occurred';
    }
  }

  Future<List<GQLFeedItem>> getTrendingFeed(
      bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { ${lang != null ? "byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('TrendingFeed',
        "query TrendingFeed {\n  trendingFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getTrendingTagFeed(
      String tag, bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true, firstUpload: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { byTag: {_eq: \"$tag\"} \n ${lang != null ? "byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('TrendingTagFeed',
        "query TrendingTagFeed {\n  trendingFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getFirstUploadsFeed(
      bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true, firstUpload: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { ${lang != null ? "byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('FirstUploadsFeed',
        "query FirstUploadsFeed {\n  trendingFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getNewUploadsFeed(
      bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { ${lang != null ? "byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('NewUploadsFeed',
        "query NewUploadsFeed {\n  socialFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getMyFeed(
      String username, bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { byFollower: \"$username\"${lang != null ? ", byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('MyFeed',
        "query MyFeed {\n  socialFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getRelated(
      String author, String permlink, String? lang) async {
    var spkVideoQuery =
        "\nauthor: \"$author\", permlink: \"$permlink\"\nspkvideo: {only: true }\n";
    var feedOptionsQuery =
        "\nfeedOptions: { ${lang != null ? "byLang: {_eq: \"$lang\"}" : ""} }\n";
    return getGQLFeed('RelatedFeed',
        "query RelatedFeed {\n  relatedFeed($spkVideoQuery$feedOptionsQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getUserFeed(
      List<String> authors, bool isShorts, int skip, String? lang) async {
    var authorsQuery = "{_in: [${authors.map((e) => '"$e"').join(",")}]}";
    var spkVideoQuery =
        "\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { byCreator: $authorsQuery ${lang != null ? ", byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('UserChannelFeed',
        "query UserChannelFeed {\n  socialFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getSearchFeed(
      String term, bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nsearchTerm: \"$term\"\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { ${lang != null ? ", byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('SearchFeed',
        "query SearchFeed {\n  searchFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getCommunity(
      String community, bool isShorts, int skip, String? lang) async {
    var spkVideoQuery =
        "\nspkvideo: {only: true${isShorts ? ", isShort: true" : ""}}\n";
    var feedOptionsQuery =
        "\nfeedOptions: { byCommunity: { _eq: \"$community\" } ${lang != null ? ", byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('CommunityFeed',
        "query CommunityFeed {\n  socialFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<GQLFeedItem>> getCTTFeed(int skip, String? lang) async {
    var authors = ["spknetwork.chat", "neopch.ctt", "noakmilo.ctt"];
    var authorsQuery = "{_in: [${authors.map((e) => '"$e"').join(",")}]}";
    var spkVideoQuery = "\nspkvideo: {only: true }\n";
    var feedOptionsQuery =
        "\nfeedOptions: { byCreator: $authorsQuery ${lang != null ? ", byLang: {_eq: \"$lang\"}" : ""} }\n";
    var paginationQuery = "\npagination: { limit: 50, skip: $skip }\n";
    return getGQLFeed('UserChannelFeed',
        "query UserChannelFeed {\n  socialFeed($spkVideoQuery$feedOptionsQuery$paginationQuery)\n$dataQuery");
  }

  Future<List<VideoCommentModel>> getHiveComments(
      String userName, String permLink) async {
    try {
      var headers = {
        'Connection': 'keep-alive',
        'content-type': 'application/json',
      };
      var body = json.encode({
        "query":
            "query GetComments {\n  socialPost(author: \"$userName\", permlink: \"$permLink\") {\n    ... on HivePost {\n      children {\n        ... on HivePost {\n          body\n          permlink\n          created_at\n          author {\n            username\n          }\n          stats {\n            num_votes\n          }\n          children {\n            ... on HivePost {\n              body\n              permlink\n              created_at\n              author {\n                username\n              }\n              stats {\n                num_votes\n              }\n            }\n            children {\n              ... on HivePost {\n                body\n                permlink\n                created_at\n                author {\n                  username\n                }\n                stats {\n                  num_votes\n                }\n              }\n            }\n          }\n        }\n      }\n      body\n    }\n  }\n}",
        "operationName": "GetComments",
        "extensions": {}
      });
      http.Response response = await post(
          Uri.parse('https://union.us-02.infra.3speak.tv/api/v2/graphql'),
          headers: headers,
          body: body);

      if (response.statusCode == 200) {
        var string = response.body;
        return GQLHiveCommentReponse.fromRawJson(string)
                .data
                .socialPost
                .children ??
            [];
      } else {
        throw response.reasonPhrase ?? 'Error occurred';
      }
    } catch (e) {
      throw e;
    }
  }

  Future<GQLFeedItem> getVideoDetails(String author, String permlink) async {
    var headers = {
      'Connection': 'keep-alive',
      'content-type': 'application/json',
    };
    const storage = FlutterSecureStorage();
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    String gqlServer = "https://$union/api/v2/graphql";
    var request = http.Request('POST', Uri.parse(gqlServer));
    var query =
        "query MyQuery {\n  socialPost(author: \"edmundochauran\", permlink: \"dbgmwaox\") {\n    ... on HivePost {\n      spkvideo\n      title\n      lang\n      json_metadata {\n        raw\n      }\n      created_at\n      tags\n      author {\n        username\n      }\n      permlink\n      stats {\n        num_comments\n        num_votes\n        total_hive_reward\n      }\n      community\n      body\n      app_metadata\n    }\n  }\n}";
    request.body = json
        .encode({"query": query, "operationName": "MyQuery", "extensions": {}});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var responseData = VideoDetailsFeed.fromRawJson(string);
      return responseData.item;
    } else {
      print(response.reasonPhrase);
      throw response.reasonPhrase ?? 'Error occurred';
    }
  }

  Future<List<CommentItemModel>> getComments(
      String author, String permlink) async {
    try {
      var headers = {'content-type': 'application/json'};
      var request = http.Request('POST', Uri.parse('https://api.hive.blog/'));
      request.body = json.encode({
        "id": 9,
        "jsonrpc": "2.0",
        "method": "bridge.get_discussion",
        "params": {"author": author, "permlink": permlink}
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        CommentResponseModel commentResponse = CommentResponseModel.fromRawJson(
            await response.stream.bytesToString());
        return commentResponse.comments;
      } else {
        throw (response.reasonPhrase.toString());
      }
    } catch (e) {
      throw (e.toString());
    }
  }
}
