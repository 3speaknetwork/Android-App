import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/hive_post_info/hive_post_info.dart';
import 'package:acela/src/models/home_screen_feed_models/home_feed.dart';
import 'package:acela/src/screens/video_details_screen/video_details_screen.dart';
import 'package:acela/src/screens/video_details_screen/video_details_view_model.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/list_tile_video.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

class UserChannelVideos extends StatefulWidget {
  const UserChannelVideos({
    Key? key,
    required this.owner,
    required this.rpc,
  }) : super(key: key);
  final String owner;
  final String rpc;

  @override
  State<UserChannelVideos> createState() => UserChannelVideosState();
}

class UserChannelVideosState extends State<UserChannelVideos>
    with AutomaticKeepAliveClientMixin<UserChannelVideos> {
  @override
  bool get wantKeepAlive => true;
  var isLoading = false;
  List<HomeFeedItem> list = [];
  Map<String, PayoutInfo?> payout = {};

  @override
  void initState() {
    super.initState();
    loadFeed();
  }

  void sortByNewest() {
    setState(() {
      list.sort((a, b) {
        return (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now());
      });
      list = list.reversed.toList();
    });
  }

  void sortByMostViewed() {
    setState(() {
      list.sort((a, b) {
        return a.views > b.views
            ? -1
            : a.views < b.views
                ? 1
                : 0;
      });
    });
  }

  void loadFeed() async {
    setState(() {
      isLoading = true;
    });
    var response =
        await get(Uri.parse("${server.domain}/apiv2/feeds/@${widget.owner}"));
    if (response.statusCode == 200) {
      List<HomeFeedItem> list = homeFeedItemFromString(response.body);
      setState(() {
        this.list = list;
        isLoading = false;
      });
      var i = 0;
      Timer.periodic(const Duration(seconds: 1), (timer) {
        fetchHiveInfo(list[i].author, list[i].permlink, widget.rpc);
        i += 1;
        if (i == list.length) {
          timer.cancel();
        }
      });
    } else {
      showError("Status code is ${response.statusCode}");
      setState(() {
        this.list = [];
        isLoading = false;
      });
    }
  }

  // fetch hive info
  void fetchHiveInfo(String user, String permlink, String hiveApiUrl) async {
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
      setState(() {
        var upVotes = result.activeVotes.where((e) => e.rshares > 0).length;
        var downVotes = result.activeVotes.where((e) => e.rshares < 0).length;
        payout["$user/$permlink"] = PayoutInfo(
          payout: result.payout,
          downVotes: downVotes,
          upVotes: upVotes,
        );
      });
    } else {
      print(response.reasonPhrase);
    }
  }

  Widget _tileTitle(HomeFeedItem item, BuildContext context,
      Function(HomeFeedItem) onUserTap) {
    String timeInString =
        item.createdAt != null ? "📆 ${timeago.format(item.createdAt!)}" : "";
    String duration = "🕚 ${Utilities.formatTime(item.duration.toInt())}";
    String views = "▶ ${item.views}";
    double? payoutAmount = payout["${item.author}/${item.permlink}"]?.payout;
    int? upVotes = payout["${item.author}/${item.permlink}"]?.upVotes;
    int? downVotes = payout["${item.author}/${item.permlink}"]?.downVotes;
    return ListTileVideo(
      placeholder: 'assets/branding/three_speak_logo.png',
      url: item.images.thumbnail,
      userThumbUrl: server.userOwnerThumb(item.author),
      title: item.title,
      subtitle: "$timeInString $duration $views",
      onUserTap: () {
        onUserTap(item);
      },
      user: item.author,
      permlink: item.permlink,
      shouldResize: true,
      isIpfs: item.playUrl.contains('ipfs'),
    );
  }

  Widget _listTile(HomeFeedItem item, BuildContext context,
      Function(HomeFeedItem) onTap, Function(HomeFeedItem) onUserTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 0,
      title: _tileTitle(item, context, onUserTap),
      onTap: () {
        onTap(item);
      },
    );
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _futureVideos() {
    if (isLoading) {
      return const LoadingScreen(
        title: 'Loading Data',
        subtitle: 'Please wait',
      );
    }
    if (list.isEmpty) {
      return Center(child: const Text('No videos found.'));
    }
    return ListView.separated(
      itemBuilder: (context, index) {
        return _listTile(list[index], context, (item) {
          var viewModel = VideoDetailsViewModel(
              author: item.author, permlink: item.permlink);
          // Navigator.of(context).push(MaterialPageRoute(
          //     builder: (context) => VideoDetailsScreen(vm: viewModel)));
        }, (owner) {
          log("tapped on user ${owner.author}");
        });
      },
      separatorBuilder: (context, index) =>
          const Divider(thickness: 0, height: 15, color: Colors.transparent),
      itemCount: list.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _futureVideos();
  }
}
