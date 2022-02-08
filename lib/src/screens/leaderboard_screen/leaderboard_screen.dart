import 'dart:developer';
import 'dart:core';
import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/leaderboard_models/leaderboard_model.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<List<LeaderboardResponseItem>> getData() async {
    var response = await get(Uri.parse("${server.domain}/apiv2/leaderboard"));
    if (response.statusCode == 200) {
      return leaderboardResponseItemFromString(response.body);
    } else {
      throw "Status code not 200";
    }
  }

  Widget _listTileSubtitle(LeaderboardResponseItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rank: ${item.rank}\nScore: ${item.score}"),
        Container(
          height: 5,
        ),
        LinearProgressIndicator(
          value: item.score / 1000,
        )
      ],
    );
  }

  Widget _medalTile(LeaderboardResponseItem item, String medal) {
    return ListTile(
      leading: CustomCircleAvatar(
        width: 60,
        height: 60,
        url: server.userOwnerThumb(item.username),
      ),
      title: Row(
        children: [
          CircleAvatar(
            child: Text(medal),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(item.username),
        ],
      ),
      subtitle: _listTileSubtitle(item),
      onTap: () {
        log("user tapped on ${item.username}");
      },
    );
  }

  Widget _listTile(LeaderboardResponseItem item) {
    return ListTile(
      leading: CustomCircleAvatar(
        width: 60,
        height: 60,
        url: server.userOwnerThumb(item.username),
      ),
      title: Text(item.username),
      subtitle: _listTileSubtitle(item),
      onTap: () {
        log("user tapped on ${item.username}");
      },
    );
  }

  Widget _list(List<LeaderboardResponseItem> data) {
    return ListView.separated(
        itemBuilder: (context, index) {
          return index == 0
              ? _medalTile(data[index], '🥇')
              : index == 1
                  ? _medalTile(data[index], '🥈')
                  : index == 2
                      ? _medalTile(data[index], '🥉')
                      : _listTile(data[index]);
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: data.length);
  }

  Widget _body() {
    return FutureBuilder<List<LeaderboardResponseItem>>(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return RetryScreen(
                error: snapshot.error?.toString() ?? "Something went wrong",
                onRetry: getData,
              );
            } else if (snapshot.hasData) {
              return Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                child: _list(snapshot.data!.take(100).toList()),
              );
            } else {
              return RetryScreen(
                error: "Something went wrong",
                onRetry: getData,
              );
            }
          } else {
            return const LoadingScreen();
          }
        },
        future: getData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
      ),
      body: _body(),
    );
  }
}