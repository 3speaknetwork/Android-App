/*
import 'package:acela/src/screens/stories/new_stories_feed.dart';
import 'package:acela/src/screens/stories/stories_feed.dart';
import 'package:flutter/material.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  static List<Tab> tabs = [
    Tab(child: Image.asset('assets/ctt-logo.png')),
    Tab(icon: const Icon(Icons.video_camera_front_outlined)),
  ];
  var fitWidth = true;
  var cttKey = Key('ctt');
  var feedKey = Key('feed');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Builder(
        builder: (context) {
          var appBar = AppBar(
            centerTitle: true,
            title: Row(
              children: [
                Image.asset(
                  "assets/branding/three_shorts_icon.png",
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 15),
                const Text('3Shorts')
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    cttKey = new Key('ctt+${DateTime.now().toIso8601String()}');
                    feedKey = new Key('feed+${DateTime.now().toIso8601String()}');
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: TabBar(
              tabs: tabs,
            ),
          );
          return Scaffold(
            appBar: appBar,
            body: TabBarView(
              children: [
                NewStoriesFeedScreen(isCTT: true, key: cttKey),
                NewStoriesFeedScreen(isCTT: false, key: feedKey),
              ],
            ),
          );
        },
      ),
    );
  }
}

 */
