import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:acela/src/widgets/story_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class StoryFeedDataBody extends StatefulWidget {
  const StoryFeedDataBody(
      {Key? key,
      required this.items,
      required this.appData,
      required this.controller})
      : super(key: key);

  final List<GQLFeedItem> items;
  final HiveUserData appData;
  final CarouselController controller;

  @override
  State<StoryFeedDataBody> createState() => _StoryFeedDataBodyState();
}

class _StoryFeedDataBodyState extends State<StoryFeedDataBody> {
  @override
  Widget build(BuildContext context) {
    return carousel(widget.items,context);
  }

  Widget _fullPost(GQLFeedItem item) {
    return StoryPlayer(
      item: item,
      data: widget.appData,
      didFinish: () {
        setState(() {
          widget.controller.nextPage();
        });
      },
    );
  }

  Widget carousel(List<GQLFeedItem> items, BuildContext context) {
    return Container(
      child: CarouselSlider(
        carouselController: widget.controller,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height,
          enableInfiniteScroll: true,
          viewportFraction: 1,
          scrollDirection: Axis.vertical,
        ),
        items: items.map((item) {
          return Builder(
            builder: (BuildContext context) {
              return _fullPost(item);
            },
          );
        }).toList(),
      ),
    );
  }
}
