import 'dart:async';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/communities_models/request/community_details_request.dart';
import 'package:acela/src/models/communities_models/response/community_details_response_models.dart';
import 'package:acela/src/models/home_screen_feed_models/home_feed.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_list.dart';
import 'package:acela/src/screens/video_details_screen/video_details_screen.dart';
import 'package:acela/src/screens/video_details_screen/video_details_view_model.dart';
import 'package:acela/src/utils/routes/routes.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen(
      {Key? key, required this.name, required this.title})
      : super(key: key);
  final String name;
  final String title;

  @override
  _CommunityDetailScreenState createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, PayoutInfo?> payout = {};
  static List<Tab> tabs = [
    Tab(text: 'Videos'),
    Tab(
      icon: Image.asset(
        'assets/branding/three_shorts_icon.png',
        width: 30,
        height: 30,
      ),
    ),
    Tab(text: 'About'),
    Tab(text: 'Team')
  ];

  Future<List<HomeFeedItem>>? _loadingFeed;
  Future<CommunityDetailsResponse>? _details;

  Future<List<HomeFeedItem>> _loadHomeFeed() async {
    var uri =
        Uri.parse('${server.domain}/apiv2/feeds/community/${widget.name}/new');
    var response = await get(uri);
    if (response.statusCode == 200) {
      List<HomeFeedItem> list = homeFeedItemFromString(response.body);
      return list;
    } else {
      throw 'Status code ${response.statusCode}';
    }
  }

  Future<CommunityDetailsResponse> _loadDetails(String hiveApiUrl) async {
    var client = http.Client();
    var body = CommunityDetailsRequest.forName(widget.name).toJsonString();
    var response =
        await client.post(Uri.parse('https://$hiveApiUrl'), body: body);
    if (response.statusCode == 200) {
      return CommunityDetailsResponse.fromString(response.body);
    } else {
      throw "Status code is ${response.statusCode}";
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void onTap(HomeFeedItem item) {
    var viewModel =
        VideoDetailsViewModel(author: item.author, permlink: item.permlink);
    // Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => VideoDetailsScreen(vm: viewModel)));
  }

  void onUserTap(HomeFeedItem item) {
    context.pushNamed(Routes.userView, pathParameters: {'author': item.author});
  }

  Widget _screen(HiveUserData appData) {
    return HomeScreenFeedList(
      feedType: HomeScreenFeedType.community,
      appData: appData,
      community: widget.name,
    );
  }



  String _generateMarkDown(CommunityDetailsResponse data) {
    return "## About:\n${data.result.about}\n\n## Information:\n${data.result.description}\n\n## Flags:\n${data.result.flagText}\n\n## Total Authors:\n${data.result.numAuthors}\n\n## Subscribers:\n${data.result.subscribers}\n\n## Created At:\n${Utilities.parseAndFormatDateTime(data.result.createdAt)}";
  }

  Widget _descriptionMarkDown(String markDown) {
    return Markdown(
      data: Utilities.removeAllHtmlTags(markDown),
      onTapLink: (text, url, title) {
        launchUrl(Uri.parse(url ?? 'https://google.com'));
      },
    );
  }

  Widget _about(HiveUserData appData) {
    return FutureBuilder(
      future: _details,
      builder: (builder, snapshot) {
        if (snapshot.hasError) {
          return RetryScreen(
              error: snapshot.error?.toString() ?? 'Something went wrong',
              onRetry: () {
                setState(() {
                  _details = null;
                });
              });
        } else if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          CommunityDetailsResponse data =
              snapshot.data! as CommunityDetailsResponse;
          return _descriptionMarkDown(_generateMarkDown(data));
        } else {
          return const LoadingScreen(
            title: 'Loading Data',
            subtitle: 'Please wait',
          );
        }
      },
    );
  }

  Widget _team(HiveUserData appData) {
    return FutureBuilder(
      future: _details,
      builder: (builder, snapshot) {
        if (snapshot.hasError) {
          return RetryScreen(
            error: snapshot.error?.toString() ?? 'Something went wrong',
            onRetry: () {
              setState(() {
                _details = null;
              });
            },
          );
        } else if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          CommunityDetailsResponse data =
              snapshot.data! as CommunityDetailsResponse;
          return ListView.separated(
            itemBuilder: (context, index) {
              return ListTile(
                leading: CustomCircleAvatar(
                  height: 40,
                  width: 40,
                  url: server.userOwnerThumb(data.result.team[index][0]),
                ),
                title: Text(data.result.team[index][0]),
                subtitle: Text(data.result.team[index][1]),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: data.result.team.length,
          );
        } else {
          return const LoadingScreen(
            title: 'Loading Data',
            subtitle: 'Please wait',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    if (_loadingFeed == null) {
      setState(() {
        _loadingFeed = _loadHomeFeed();
      });
    }
    if (_details == null) {
      setState(() {
        _details = _loadDetails(appData.rpc);
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CustomCircleAvatar(
              height: 40,
              width: 40,
              url: server.communityIcon(widget.name),
            ),
            const SizedBox(width: 10),
            Text(widget.title)
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _screen(appData),
          SizedBox(),
          _about(appData),
          _team(appData),
        ],
      ),
    );
  }
}
