/*
import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/home_screen_feed_models/home_feed.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/story_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show get;
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';


class NewStoriesFeedScreen extends StatefulWidget {
  const NewStoriesFeedScreen({
    Key? key,
    required this.isCTT,
  }) : super(key: key);
  final bool isCTT;

  @override
  State<NewStoriesFeedScreen> createState() => _NewStoriesFeedScreenState();
}

class _NewStoriesFeedScreenState extends State<NewStoriesFeedScreen> {
  CarouselSliderController controller = CarouselSliderController();
  Future<List<HomeFeedItem>>? _future;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    _future = _loadAllFeeds();
  }

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable();
  }

  Future<List<HomeFeedItem>> _loadAllFeeds() async {
    if (widget.isCTT) {
      var cttItems =
          await _loadFeed("${server.domain}/apiv2/feeds/@spknetwork.chat");
      return cttItems
          .where((e) => (e.isShorts == true || e.duration <= 90.0))
          .toList();
    } else {
      var homeItems = await _loadFeed("${server.domain}/apiv2/feeds/Home");
      var newItems = await _loadFeed("${server.domain}/apiv2/feeds/new");
      // List<HomeFeedItem> newItems = [];
      var trendingItems =
          await _loadFeed("${server.domain}/apiv2/feeds/trending");
      var firstUploadsItems =
          await _loadFeed("${server.domain}/apiv2/feeds/firstUploads");
      return [...homeItems, ...trendingItems, ...newItems, ...firstUploadsItems]
          .toSet()
          .toList()
          .where((e) => ((e.isShorts == true || e.duration <= 90.0) && e.author != "spknetwork.chat"))
          .toList();
    }
  }

  Future<List<HomeFeedItem>> _loadFeed(String path) async {
    var response = await get(Uri.parse(path));
    if (response.statusCode == 200) {
      List<HomeFeedItem> list = homeFeedItemFromString(response.body);
      return list;
    } else {
      throw 'Status code ${response.statusCode}';
    }
  }

  Widget _fullPost(HomeFeedItem item, HiveUserData data) {
    return StoryPlayer(
      playUrl: item.getVideoUrl(data),
      hlsUrl: item.playUrl,
      thumbUrl: item.images.thumbnail,
      data: data,
      item: null,
      homeFeedItem: item,
      isPortrait: widget.isCTT ? true : false,
      didFinish: () {
        setState(() {
          controller.nextPage();
        });
      },
    );
  }

  Widget carousel(HiveUserData data, List<HomeFeedItem> items) {
    return Container(
      child: CarouselSlider(
        CarouselSliderController: controller,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height,
          enableInfiniteScroll: true,
          viewportFraction: 1,
          scrollDirection: Axis.vertical,
        ),
        items: items.map((item) {
          return Builder(
            builder: (BuildContext context) {
              return _fullPost(item, data);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget loadingData() {
    return const LoadingScreen(
      title: 'Loading Data',
      subtitle: 'Please wait',
    );
  }

  @override
  Widget build(BuildContext context) {
    var userData = Provider.of<HiveUserData>(context);
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading data. Please try again');
        } else if (snapshot.connectionState == ConnectionState.done) {
          return carousel(userData, snapshot.data as List<HomeFeedItem>);
        } else {
          return loadingData();
        }
      },
    );
  }
}

 */
