import 'dart:developer';

import 'package:acela/src/models/hive_comments/new_hive_comment/new_hive_comment.dart';
import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:flutter/material.dart';

class CommentController extends ChangeNotifier {
  final GQLCommunicator _gqlCommunicator = GQLCommunicator();
  ViewState viewState = ViewState.loading;
  List<CommentItemModel> items = [];

  final String author;
  final String permlink;

  CommentController({required this.author, required this.permlink}) {
    _init();
  }

  void _init() async {
    try {
      items = [...await _gqlCommunicator.getComments(author, permlink)];
      log(author);
      log(permlink);
      items = refactorComments(items, permlink);
      items.forEach((element) {
        print(
            "author- ${element.author} parentAuthor- ${element.parentAuthor} parentpermlink- ${element.parentPermlink} permlink- ${element.permlink}");
      });
      if (items.isEmpty) {
        viewState = ViewState.empty;
      } else {
        viewState = ViewState.data;
      }
      notifyListeners();
    } catch (e) {
      viewState = ViewState.error;
      notifyListeners();
    }
  }

  void addTopLevelComment(CommentItemModel comment) {
    items = [
      comment,
      ...items,
    ];
    notifyListeners();
  }

  void addSubLevelComment(CommentItemModel comment, int index) {
    items.insert(index + 1, comment);
    items = [
      ...items,
    ];
    log('localy added');
    notifyListeners();
  }

  void onUpvote(CommentItemModel comment, int index) {
    items[index] = comment.copyWith(activeVotes: [
      ...comment.activeVotes,
    ]);
    notifyListeners();
  }

  void refreshSilently() async {
    viewState = ViewState.loading;
    notifyListeners();
    _init();
  }

  static List<CommentItemModel> refactorComments(
      List<CommentItemModel> content, String parentPermlink) {
    List<CommentItemModel> refactoredComments = [];
    var newContent = List<CommentItemModel>.from(content);
    for (var e in newContent) {
      e.visited = false;
    }
    newContent.sort((a, b) {
      var bTime = b.created;
      var aTime = a.created;
      if (aTime.isAfter(bTime)) {
        return -1;
      } else if (bTime.isAfter(aTime)) {
        return 1;
      } else {
        return 0;
      }
    });
    refactoredComments.addAll(
        newContent.where((e) => e.parentPermlink == parentPermlink).toList());
    while (refactoredComments.where((e) => e.visited == false).isNotEmpty) {
      var firstComment =
          refactoredComments.where((e) => e.visited == false).first;
      var indexOfFirstElement = refactoredComments.indexOf(firstComment);
      if (firstComment.children != 0) {
        List<CommentItemModel> children = newContent
            .where((e) => e.parentPermlink == firstComment.permlink)
            .toList();
        children.sort((a, b) {
          var aTime = a.created;
          var bTime = b.created;
          if (aTime.isAfter(bTime)) {
            return -1;
          } else if (bTime.isAfter(aTime)) {
            return 1;
          } else {
            return 0;
          }
        });
        refactoredComments.insertAll(indexOfFirstElement + 1, children);
      }
      firstComment.visited = true;
    }
    log('Returning ${refactoredComments.length} elements');
    return refactoredComments;
  }
}
