import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/action_response.dart';
import 'package:acela/src/models/communities_models/request/communities_request_model.dart';
import 'package:acela/src/models/communities_models/response/communities_response_models.dart';
import 'package:acela/src/models/hive_post_info/hive_post_info.dart';
import 'package:acela/src/models/hive_post_info/hive_user_posting_key.dart';
import 'package:acela/src/models/home_screen_feed_models/home_feed.dart';
import 'package:acela/src/models/login/memo_response.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/podcast/upload/podcast_episode_upload_response.dart';
import 'package:acela/src/models/user_account/action_response.dart';
import 'package:acela/src/models/user_account/user_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/models/video_upload/does_post_exists.dart';
import 'package:acela/src/models/video_upload/video_device_encode_upload_model.dart';
import 'package:acela/src/models/video_upload/video_upload_complete_request.dart';
import 'package:acela/src/models/video_upload/video_upload_login_response.dart';
import 'package:acela/src/models/video_upload/video_upload_prepare_response.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class VideoSize {
  double width;
  double height;

  VideoSize({
    required this.width,
    required this.height,
  });
}

class Communicator {
  // Production
  static const tsServer = "https://studio.3speak.tv";
  static const fsServer = "https://uploads.3speak.tv/files";

  // Android
  // static const fsServer = "http://10.0.2.2:1080/files";
  // static const tsServer = "http://10.0.2.2:13050";

  // iOS
  // static const tsServer = "http://localhost:13050";
  // static const fsServer = "http://localhost:1080/files";

  // iOS Devices - Local Server Testing
  // static const tsServer = "http://192.168.29.53:13050";
  // static const fsServer = "http://192.168.29.53:1080/files";

  // iOS Devices - Local server testing different router
  // static const tsServer = "http://192.168.1.4:13050";
  // static const fsServer = "http://192.168.1.4:1080/files";

  // static const hiveApiUrl = 'api.hive.blog';
  static const threeSpeakCDN = 'https://ipfs-3speak.b-cdn.net';
  static const hiveAuthServer = 'wss://hive-auth.arcange.eu';
  static const acelaServer = 'https://acela.us-02.infra.3speak.tv';

  Future<bool> doesPostNotExist(
    String user,
    String post,
    String hiveApiUrl,
  ) async {
    var response = await http.post(
      Uri.parse('https://$hiveApiUrl'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "id": 1,
        "jsonrpc": "2.0",
        "method": "bridge.get_discussion",
        "params": {
          "author": user,
          "permlink": post,
          "observer": user,
        }
      }),
    );
    var resultString = response.body;
    var data = DoesPostExistsResponse.fromJsonString(resultString);
    var error = data.error?.data ?? "";
    return error.contains("does not exist");
  }

  Future<VideoSize> getAspectRatio(String playUrl) async {
    var request = http.Request('GET', Uri.parse(playUrl));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var exp = RegExp(r"RESOLUTION=(.+),");
      var matches = exp.allMatches(responseBody);
      if (matches.isEmpty) {
        exp = RegExp(r"RESOLUTION=(.+)\n");
        matches = exp.allMatches(responseBody);
      }
      if (matches.isNotEmpty) {
        var firstMatch = (matches.first.group(0) ?? '')
            .replaceAll('RESOLUTION=', '')
            .replaceAll(',', '')
            .replaceAll('\n', '');
        var comps = firstMatch.split("x");
        if (comps.length == 2) {
          var width = double.tryParse(comps[0]);
          var height = double.tryParse(comps[1]);
          if (width != null && height != null) {
            return VideoSize(width: width, height: height);
          } else {
            return VideoSize(width: 320, height: 160);
          }
        } else {
          return VideoSize(width: 320, height: 160);
        }
      } else {
        return VideoSize(width: 320, height: 160);
      }
    } else {
      log(response.reasonPhrase.toString());
      throw response.reasonPhrase.toString();
    }
  }

  Future<String> getPublicKey(String user, String hiveApiUrl) async {
    var request = http.Request('POST', Uri.parse('https://$hiveApiUrl'));
    request.body = json.encode({
      "id": 8,
      "jsonrpc": "2.0",
      "method": "database_api.find_accounts",
      "params": {
        "accounts": [user]
      }
    });
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var key = HiveUserPostingKey.fromString(responseBody);
      return key.publicPostingKey;
    } else {
      log(response.reasonPhrase.toString());
      throw response.reasonPhrase.toString();
    }
  }

  Future<List<CommunityItem>> getListOfCommunities(
    String? query,
    String hiveApiUrl,
  ) async {
    var client = http.Client();
    var body =
        CommunitiesRequestModel(params: CommunitiesRequestParams(query: query))
            .toJsonString();
    var response =
        await client.post(Uri.parse('https://$hiveApiUrl'), body: body);
    if (response.statusCode == 200) {
      var communitiesResponse =
          communitiesResponseModelFromString(response.body);
      return communitiesResponse.result;
    } else {
      throw "Status code is ${response.statusCode}";
    }
  }

  Future<PayoutInfo> fetchHiveInfo(
    String user,
    String permlink,
    String hiveApiUrl,
  ) async {
    var request = http.Request('POST', Uri.parse('https://$hiveApiUrl'));
    request.body = json.encode({
      "id": 1,
      "jsonrpc": "2.0",
      "method": "bridge.get_discussion",
      "params": {"author": user, "permlink": permlink, "observer": ""}
    });
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var result = HivePostInfo.fromJsonString(string)
          .result
          .resultData
          .where((element) => element.permlink == permlink)
          .first;
      var upVotes = result.activeVotes.where((e) => e.rshares > 0).length;
      var downVotes = result.activeVotes.where((e) => e.rshares < 0).length;
      return PayoutInfo(
        payout: result.payout,
        downVotes: downVotes,
        upVotes: upVotes,
      );
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<String> _getAccessToken(
      HiveUserData user, String encryptedToken) async {
    const platform = MethodChannel('com.example.acela/auth');
    var key = user.postingKey == null && user.keychainData != null
        ? dotenv.env['MOBILE_CLIENT_PRIVATE_KEY']
        : user.postingKey ?? "";
    final String result = await platform.invokeMethod('encryptedToken', {
      'username': user.username,
      'postingKey': key,
      'encryptedToken': encryptedToken,
    });
    var memo = MemoResponse.fromJsonString(result);
    if (memo.error.isNotEmpty) {
      throw memo.error;
    } else if (memo.decrypted.isEmpty) {
      throw 'Decrypted memo is empty';
    }
    return memo.decrypted.replaceFirst("#", '');
  }

  Future<String> getValidCookie(HiveUserData user) async {
    var uri = '${Communicator.tsServer}/mobile/login?username=${user.username}';
    if (user.keychainData != null && user.postingKey == null) {
      uri =
          '${Communicator.tsServer}/mobile/login?username=${user.username}&client=mobile';
    }
    var map;
    if (user.cookie != null) {
      map = {"cookie": user.cookie!};
    }
    try {
      http.Response response = await get(Uri.parse(uri), headers: map);
      if (response.statusCode == 200) {
        var string = response.body;
        var loginResponse = VideoUploadLoginResponse.fromJsonString(string);
        if (loginResponse.error != null && loginResponse.error!.isNotEmpty) {
          throw 'Error - ${loginResponse.error}';
        } else if (loginResponse.memo != null &&
            loginResponse.memo!.isNotEmpty) {
          var token = await _getAccessToken(user, loginResponse.memo!);
          var url =
              '${Communicator.tsServer}/mobile/login?username=${user.username}&access_token=$token';
          var request = http.Request('GET', Uri.parse(url));
          http.StreamedResponse response = await request.send();
          var string = await response.stream.bytesToString();
          var tokenResponse = VideoUploadLoginResponse.fromJsonString(string);
          var cookie = response.headers['set-cookie'];
          if (tokenResponse.error != null && tokenResponse.error!.isNotEmpty) {
            throw 'Error - ${tokenResponse.error}';
          } else if (tokenResponse.network == "hive" &&
              tokenResponse.banned != true &&
              tokenResponse.userId != null &&
              cookie != null &&
              cookie.isNotEmpty) {
            const storage = FlutterSecureStorage();
            await storage.write(key: 'cookie', value: cookie);
            String resolution = await storage.read(key: 'resolution') ?? '480p';
            String rpc = await storage.read(key: 'rpc') ?? 'api.hive.blog';
            String union = await storage.read(key: 'union') ??
                GQLCommunicator.defaultGQLServer;
            var newData = HiveUserData(
              username: user.username,
              postingKey: user.postingKey,
              keychainData: user.keychainData,
              union: union,
              cookie: cookie,
              postingAuthority: null,
              accessToken: null,
              resolution: resolution,
              rpc: rpc,
              loaded: true,
              language: user.language,
            );
            server.updateHiveUserData(newData);
            return cookie;
          } else {
            log('This should never happen. No error, no user info. How?');
            throw 'Something went wrong.';
          }
        } else if (loginResponse.network == "hive" &&
            loginResponse.banned != true &&
            loginResponse.userId != null &&
            user.cookie != null) {
          return user.cookie!;
        } else {
          log('This should never happen. No error, no memo, no user info. How?');
          throw 'Something went wrong.';
        }
      } else if (response.statusCode == 500) {
        var string = response.body;
        var errorResponse = VideoUploadLoginResponse.fromJsonString(string);
        if (errorResponse.error != null &&
            errorResponse.error!.isNotEmpty &&
            errorResponse.error == 'session expired') {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'cookie');
          String resolution = await storage.read(key: 'resolution') ?? '480p';
          String rpc = await storage.read(key: 'rpc') ?? 'api.hive.blog';
          String union = await storage.read(key: 'union') ??
              GQLCommunicator.defaultGQLServer;
          var newData = HiveUserData(
            postingAuthority: null,
            accessToken: null,
            username: user.username,
            postingKey: user.postingKey,
            keychainData: user.keychainData,
            cookie: null,
            resolution: resolution,
            rpc: rpc,
            union: union,
            loaded: true,
            language: user.language,
          );
          server.updateHiveUserData(newData);
          return await getValidCookie(newData);
        } else {
          throw errorResponse.error.toString();
        }
      } else {
        throw 'Status code ${response.statusCode}';
      }
    } catch (e) {
      throw e;
    }
  }

  Future<VideoUploadInfo> uploadInfo({
    required HiveUserData user,
    required String thumbnail,
    required String oFilename,
    required int duration,
    required double size,
    required String tusFileName,
  }) async {
    var cookie = await getValidCookie(user);
    var request = http.Request(
        'POST', Uri.parse('${Communicator.tsServer}/mobile/api/upload_info'));
    request.body = NewVideoUploadCompleteRequest(
      size: size,
      thumbnail: thumbnail,
      oFilename: oFilename,
      duration: duration,
      filename: tusFileName,
      owner: user.username ?? '',
    ).toJsonString();
    Map<String, String> map = {
      "cookie": cookie,
      "Content-Type": "application/json"
    };
    request.headers.addAll(map);
    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        log("Successfully sent upload complete");
        var string = await response.stream.bytesToString();
        log('Video complete response is\n$string');
        return VideoUploadInfo.fromJsonString(string);
      } else {
        var string = await response.stream.bytesToString();
        var error = ErrorResponse.fromJsonString(string).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        throw error;
      }
    } catch (e) {
      log('Error from server is ${e.toString()}');
      rethrow;
    }
  }

  Future<VideoDetails> updateInfo(
      {required HiveUserData user,
      required String videoId,
      required String title,
      required String description,
      required bool isNsfwContent,
      required String tags,
      required String? thumbnail,
      required String communityID,
      required List<BeneficiariesJson> beneficiaries}) async {
    var request = http.Request(
        'POST', Uri.parse('${Communicator.tsServer}/mobile/api/update_info'));
    var bene = beneficiaries
        .map((e) => e.copyWith(account: e.account.toLowerCase()))
        .toList()
      ..sort(
          (a, b) => a.account.toLowerCase().compareTo(b.account.toLowerCase()));
    var cookie = await getValidCookie(user);
    request.body = VideoUploadCompleteRequest(
      beneficiaries: json.encode(bene.map((e) => e.toJson()).toList()),
      videoId: videoId,
      title: title,
      description: description,
      isNsfwContent: isNsfwContent,
      tags: tags,
      thumbnail: thumbnail,
      communityID: communityID,
    ).toJsonString();
    Map<String, String> map = {
      "cookie": cookie,
      "Content-Type": "application/json"
    };
    request.headers.addAll(map);
    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        log("Successfully sent upload complete");
        var string = await response.stream.bytesToString();
        log('Video complete response is\n$string');
        return VideoDetails.fromJsonString(string);
      } else {
        var string = await response.stream.bytesToString();
        var error = ErrorResponse.fromJsonString(string).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        throw error;
      }
    } catch (e) {
      log('Error from server is ${e.toString()}');
      rethrow;
    }
  }

  Future<String> saveDeviceEncodedVideo({
    required HiveUserData user,
    required VideoDeviceEncodeUploadModel data,
  }) async {
    final uri = Uri.parse('${Communicator.tsServer}/mobile/api/upload_zip');
    var cookie = await getValidCookie(user);

    Map<String, String> headers = {
      "cookie": cookie,
      "Content-Type": "application/json",
    };

    try {
      var response = await http.post(
        uri,
        headers: headers,
        body: data.toJsonString(),
      );

      if (response.statusCode == 200) {
        log("Successfully sent upload complete");
        log('Video complete response is\n${response.body}');
        return response.body;
      } else {
        var error = ErrorResponse.fromJsonString(response.body).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        throw error;
      }
    } catch (e) {
      log('Error from server is ${e.toString()}');
      rethrow;
    }
  }

  Future<VideoDetails> updateThumb({
    required HiveUserData user,
    required String videoId,
    required String thumbnail,
  }) async {
    var request = http.Request(
      'POST',
      Uri.parse('${Communicator.tsServer}/mobile/api/update_thumbnail'),
    );
    request.body = VideoThumbUpdateRequest(
      videoId: videoId,
      thumbnail: thumbnail,
    ).toJsonString();
    Map<String, String> map = {
      "cookie": user.cookie ?? "",
      "Content-Type": "application/json"
    };
    request.headers.addAll(map);
    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        log("Successfully sent upload complete");
        var string = await response.stream.bytesToString();
        log('Video complete response is\n$string');
        return VideoDetails.fromJsonString(string);
      } else {
        var string = await response.stream.bytesToString();
        var error = ErrorResponse.fromJsonString(string).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        throw error;
      }
    } catch (e) {
      log('Error from server is ${e.toString()}');
      rethrow;
    }
  }

  Future<List<VideoDetails>> loadAnyFeed(Uri uri) async {
    var request = http.Request('GET', uri);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var videos = videoItemsFromString(string);
      return videos;
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<List<VideoDetails>> loadNewHomeFeed(bool shorts,
      [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/home?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadNewTrendingFeed(bool shorts,
      [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/trending?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadNewNewFeed(bool shorts, [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/new?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadNewFirstUploadsFeed(bool shorts,
      [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/first?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadNewUserFeed(String user, bool shorts,
      [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/user/@$user/?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadNewCommunityFeed(String community, bool shorts,
      [int skip = 0]) async {
    return await loadAnyFeed(Uri.parse(
        '${Communicator.tsServer}/mobile/api/feed/community/@$community/?shorts=${shorts ? 'true' : 'false'}&skip=$skip'));
  }

  Future<List<VideoDetails>> loadMyFeedVideos(HiveUserData user,
      [bool shorts = false]) async {
    log("Starting my feed videos ${DateTime.now().toIso8601String()}");
    var text =
        '${Communicator.tsServer}/mobile/api/feed/@${user.username ?? 'sagarkothari88'}';
    if (shorts) {
      text = '$text?shorts=true';
    }
    var request = http.Request('GET', Uri.parse(text));
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      log('My Feed videos response\n\n$string\n\n');
      var videos = videoItemsFromString(string);
      log("Ended fetch videos ${DateTime.now().toIso8601String()}");
      return videos;
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<List<VideoDetails>> loadVideos(HiveUserData user) async {
    log("Starting fetch videos ${DateTime.now().toIso8601String()}");
    var cookie = await getValidCookie(user);
    var request = http.Request(
        'GET', Uri.parse('${Communicator.tsServer}/mobile/api/my-videos'));
    Map<String, String> map = {"cookie": cookie};
    request.headers.addAll(map);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      log('My videos response\n\n$string\n\n');
      var videos = videoItemsFromString(string);
      log("Ended fetch videos ${DateTime.now().toIso8601String()}");
      return videos;
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<void> updatePublishState(HiveUserData user, String videoId) async {
    var cookie = await getValidCookie(user);
    var request = http.Request('POST',
        Uri.parse('${Communicator.tsServer}/mobile/api/my-videos/iPublished'));
    request.body = "{\"videoId\": \"$videoId\"}";
    Map<String, String> map = {
      "cookie": cookie,
      "Content-Type": "application/json"
    };
    request.headers.addAll(map);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var result = VideoOpsResponse.fromJsonString(string);
      if (result.success) {
        return;
      } else {
        throw 'Error updating video status';
      }
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<void> updatePublishStateForPodcastEpisode(
      HiveUserData user, String episodeId) async {
    var cookie = await getValidCookie(user);
    var request = http.Request('POST',
        Uri.parse('${Communicator.tsServer}/mobile/api/podcast/iPublished'));
    request.body = "{\"episodeId\": \"$episodeId\"}";
    Map<String, String> map = {
      "cookie": cookie,
      "Content-Type": "application/json"
    };
    request.headers.addAll(map);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      var string = await response.stream.bytesToString();
      var result = VideoOpsResponse.fromJsonString(string);
      if (result.success) {
        return;
      } else {
        throw 'Error updating podcast status';
      }
    } else {
      var string = await response.stream.bytesToString();
      var error = ErrorResponse.fromJsonString(string).error ??
          response.reasonPhrase.toString();
      log('Error from server is $error');
      throw error;
    }
  }

  Future<bool> deleteVideo(String permlink, HiveUserData user) async {
    var cookie = await getValidCookie(user);
    Map<String, String> headers = {
      "Cookie": cookie,
      "Content-Type": "application/json"
    };
    http.Response response = await get(
        Uri.parse('https://studio.3speak.tv/mobile/api/video/$permlink/delete'),
        headers: headers);

    try {
      if (response.statusCode == 200) {
        Map map = json.decode(response.body);
        if (map['success'] && map['message'] == 'Video deleted successfully.') {
          print(response.body);
          return true;
        } else {
          return false;
        }
      } else {
        print(response.reasonPhrase);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(HiveUserData user) async {
    try {
      var cookie = await getValidCookie(user);
      Map<String, String> map = {"cookie": cookie};
      http.Response response = await get(
          Uri.parse('${Communicator.tsServer}/mobile/api/account/delete'),
          headers: map);
      if (response.statusCode == 200) {
        var map = json.decode(response.body);
        return map['success'] && map['message'] == '3Speak Account Deleted.';
      } else {
        var string = response.body;
        log(string);
        var error = ErrorResponse.fromJsonString(string).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<PodcastEpisodeUploadResponse> uploadPodcast({
    required HiveUserData user,
    required String oFilename,
    required int duration,
    required int size,
    required String title,
    required String description,
    required bool isNsfwContent,
    required String tags,
    required String thumbnail,
    required String communityID,
    required bool declineRewards,
    required String episode, // upload path where podcast episode was uploaded
  }) async {
    var request = http.Request(
        'POST', Uri.parse('${Communicator.tsServer}/mobile/api/podcast/add'));
    request.body = json.encode({
      'oFilename': oFilename,
      'duration': duration,
      'size': size,
      'isNsfwContent': isNsfwContent,
      'title': title,
      'description': description,
      'communityID': communityID,
      'thumbnail': thumbnail,
      'episode': episode,
    });
    var cookie = await getValidCookie(user);
    Map<String, String> map = {
      "cookie": cookie,
      "Content-Type": "application/json",
      "authorization": "Bearer $cookie"
    };
    request.headers.addAll(map);
    try {
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        var string = await response.stream.bytesToString();
        return PodcastEpisodeUploadResponse
            .podcastEpisodeUploadResponseFromJson(string);
      } else {
        var string = await response.stream.bytesToString();
        var error = ErrorResponse.fromJsonString(string).error ??
            response.reasonPhrase.toString();
        log('Error from server is $error');
        throw error;
      }
    } catch (e) {
      log('Error from server is ${e.toString()}');
      rethrow;
    }
  }

  Future<ActionResponse> login(
    String userName,
    String proofOfPayload,
    String proof,
  ) async {
    var headers = {
      'Accept': 'application/json, text/plain',
      'Content-Type': 'application/json'
    };
    try {
      var body = json.encode({
        "username": userName,
        "network": "hive",
        "authority_type": "posting",
        "proof_payload": proofOfPayload,
        "proof": proof
      });
      http.Response response = await post(
          Uri.parse('${Communicator.acelaServer}/api/v1/auth/login_singleton'),
          headers: headers,
          body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ActionResponse(
            data: json.decode(response.body)['access_token'],
            valid: true,
            error: '');
      } else if (response.statusCode == 400) {
        return ActionResponse(
            data: '',
            valid: false,
            error: json.decode(response.body)['reason']);
      } else {
        return ActionResponse(data: '', valid: false, error: 'Server Error');
      }
    } catch (e) {
      return ActionResponse(data: '', valid: false, error: e.toString());
    }
  }

  Future<ActionResponse> vote(
      String accessToken, String userName, String permlink) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
      "authorization": "Bearer $accessToken"
    };
    try {
      var body = json.encode({
        "author": userName,
        "permlink": permlink,
      });
      http.Response response = await post(
          Uri.parse('${Communicator.acelaServer}/api/v1/hive/vote'),
          headers: headers,
          body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ActionResponse(
            data: json.decode(response.body)['id'], valid: true, error: '');
      } else {
        log(json.decode(response.body).toString());
        return ActionResponse(data: '', valid: false, error: 'Server Error');
      }
    } catch (e) {
      return ActionResponse(data: '', valid: false, error: e.toString());
    }
  }

  Future<ActionResponse> postComment(
      {required String parentAuthor,
      required String parentPermlink,
      required String author,
      required String authorization,
      required String commentBody}) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json',
      "authorization": "Bearer $authorization"
    };
    try {
      var body = json.encode({
        "body": commentBody,
        "parent_author": parentAuthor,
        "parent_permlink": parentPermlink,
        "author": author
      });
      http.Response response = await post(
          Uri.parse('${Communicator.acelaServer}/api/v1/hive/post_comment'),
          headers: headers,
          body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ActionResponse(
            data: json.decode(response.body)['id'], valid: true, error: '');
      } else {
        return ActionResponse(data: '', valid: false, error: 'Server Error');
      }
    } catch (e) {
      return ActionResponse(data: '', valid: false, error: e.toString());
    }
  }

  Future<ActionSingleDataResponse<UserModel>> getAccountInfo(
      String accountName) async {
    try {
      final String jsonString = await MethodChannel('com.example.acela/auth')
          .invokeMethod('getAccountInfo', {
        'username': accountName,
      });

      ActionSingleDataResponse<UserModel> response =
          ActionSingleDataResponse.fromJsonString(
              jsonString, UserModel.fromJson);
      return response;
    } catch (e) {
      return ActionSingleDataResponse(
          status: ResponseStatus.failed, errorMessage: e.toString());
    }
  }
}
