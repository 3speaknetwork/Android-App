import 'dart:async';
import 'dart:developer';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/new_feed_list_item.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var text = '';
  late TextEditingController _controller;
  Timer? _timer;
  List<GQLFeedItem> results = [];
  var loading = false;

  Future<void> search(String term, HiveUserData appData) async {
    setState(() {
      loading = true;
    });
    var searchResponse =
        await GQLCommunicator().getSearchFeed(term, false, 0, appData.language);
    setState(() {
      loading = false;
      results = searchResponse;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PreferredSizeWidget _appBar(HiveUserData appData) {
    return AppBar(
      title: TextField(
        controller: _controller,
        onChanged: (value) {
          var timer = Timer(const Duration(seconds: 1), () {
            log('Text changed to $value');
            if (value.trim().length > 3) {
              search(value.trim(), appData);
            }
          });
          setState(() {
            _timer?.cancel();
            _timer = timer;
          });
        },
      ),
    );
  }

  Widget _searchResults(HiveUserData appData) {
    return ListView.separated(
      itemBuilder: (c, i) {
        var item = results[i];
        return NewFeedListItem(
          thumbUrl: item.spkvideo?.thumbnailUrl ?? '',
          author: item.author?.username ?? '',
          title: item.title ?? '',
          createdAt: item.createdAt ?? DateTime.now(),
          duration: item.spkvideo?.duration ?? 0.0,
          comments: item.stats?.numComments,
          hiveRewards: item.stats?.totalHiveReward,
          votes: item.stats?.numVotes,
          views: 0,
          permlink: item.permlink ?? '',
          onTap: () {},
          onUserTap: () {},
          item: item,
          appData: appData,
        );
      },
      separatorBuilder: (c, i) => const Divider(),
      itemCount: results.length,
    );
  }

  Widget _searchResultListView(HiveUserData appData) {
    if (results.isEmpty && !loading) {
      return Center(
        child: Text('No search result found'),
      );
    } else if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: CircularProgressIndicator()),
          const SizedBox(
            height: 10,
          ),
          Center(child: Text('Loading search results....')),
        ],
      );
    }
    return _searchResults(appData);
  }

  @override
  Widget build(BuildContext context) {
    var appData = Provider.of<HiveUserData>(context);
    return Scaffold(
      appBar: _appBar(appData),
      body: _searchResultListView(appData),
    );
  }
}
