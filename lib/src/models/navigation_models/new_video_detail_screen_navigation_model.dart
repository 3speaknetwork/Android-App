import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:flutter/material.dart';

class NewVideoDetailScreenNavigationParameter {
  final GQLFeedItem? item;
  final VoidCallback? onPop;

  NewVideoDetailScreenNavigationParameter(
      {this.item,this.onPop});
}
