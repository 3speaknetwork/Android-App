/*
import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/stories/stories_feed_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/story_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

class StoriesFeedScreen extends StatefulWidget {
  const StoriesFeedScreen({
    Key? key,
    required this.type,
    required this.height,
    required this.fitWidth,
  }) : super(key: key);
  final String type;
  final double height;
  final bool fitWidth;

  @override
  State<StoriesFeedScreen> createState() => _StoriesFeedScreenState();
}

class _StoriesFeedScreenState extends State<StoriesFeedScreen> {
  List<StoriesFeedResponseItem> items = [];
  var isLoading = false;
  var initialPage = 0;
  CarouselSliderController controller = CarouselSliderController();
  bool isFilterMenuOn = false;

  @override
  void initState() {
    super.initState();
    loadData(0);
  }

  void loadData(int length) async {
    setState(() {
      isLoading = true;
    });
    var string = '${server.domain}/api/${widget.type}/more?skip=$length';
    var response = await get(Uri.parse(string));
    if (response.statusCode == 200) {
      List<StoriesFeedResponseItem> list =
          StoriesFeedResponseItem().fromJsonString(response.body, widget.type);
      setState(() {
        isLoading = false;
        items = items +
            list
                .where((element) =>
                    element.duration <= 90 || element.isReel == true)
                .toList();
        var permlinks = Set<String>();
        items.retainWhere((x) => permlinks.add(x.permlink));
        if (items.length < 15) {
          loadData(length + list.length);
        }
      });
    } else {
      showError('Status code ${response.statusCode}');
      setState(() {
        isLoading = false;
        items = [];
      });
    }
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showMessage(String string) {
    var snackBar = SnackBar(content: Text(string));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget loadingData() {
    return const LoadingScreen(
      title: 'Loading Data',
      subtitle: 'Please wait',
    );
  }

  Widget _fullPost(StoriesFeedResponseItem item, HiveUserData data) {
    return StoryPlayer(
      playUrl: item.getVideoUrl(data),
      hlsUrl: item.playUrl,
      thumbUrl: item.thumbnailValue,
      data: data,
      item: item,
      homeFeedItem: null,
      isPortrait: false,
      didFinish: () {
        setState(() {
          controller.nextPage();
        });
      },
    );
  }

  Widget carousel(HiveUserData data) {
    return SafeArea(
      child: Container(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var userData = Provider.of<HiveUserData>(context);
    return isLoading ? loadingData() : carousel(userData);
  }
}
*/