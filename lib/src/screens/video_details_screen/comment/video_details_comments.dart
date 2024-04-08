import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/login/ha_login_screen.dart';
import 'package:acela/src/screens/video_details_screen/comment/comment_search_bar.dart';
import 'package:acela/src/screens/video_details_screen/comment/comment_view_appbar.dart';
import 'package:acela/src/screens/video_details_screen/comment/controller/comment_controller.dart';
import 'package:acela/src/screens/video_details_screen/comment/hive_comment.dart';
import 'package:acela/src/screens/video_details_screen/comment/hive_comment_dialog.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class VideoDetailsComments extends StatefulWidget {
  const VideoDetailsComments({
    Key? key,
    required this.author,
    required this.permlink,
    required this.rpc,
    required this.item,
    required this.appData,
  }) : super(key: key);
  final String author;
  final String permlink;
  final String rpc;
  final GQLFeedItem item;
  final HiveUserData appData;

  @override
  State<VideoDetailsComments> createState() => _VideoDetailsCommentsState();
}

class _VideoDetailsCommentsState extends State<VideoDetailsComments> {
  final ValueNotifier<bool> showSearchBar = ValueNotifier(false);
  final TextEditingController searchController = TextEditingController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();
  late final CommentController controller;

  @override
  void initState() {
    controller =
        CommentController(author: widget.author, permlink: widget.permlink);
    _addListener();
    super.initState();
  }

  void _addListener() {
    showSearchBar.addListener(_searchBarListener);
  }

  void _searchBarListener() async {
    if (!showSearchBar.value) {
      if (controller.animateToCommentIndex != null) {
        await Future.delayed(Duration(milliseconds: 300));
        _animteToAddedComment(controller.animateToCommentIndex!);
        controller.commentHighlighterTrigger = true;
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    showSearchBar.removeListener(_searchBarListener);
    super.dispose();
  }

  Widget commentsListView() {
    return Selector<CommentController, List<CommentItemModel>>(
      shouldRebuild: (previous, next) =>
          previous != next || previous.length != next.length,
      selector: (_, myType) => myType.disPlayedItems,
      builder: (context, items, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CommentSearchBar(
                showSearchBar: showSearchBar,
                onChanged: (value) {
                  controller.onSearch(value.trim());
                },
                textEditingController: searchController),
            items.isNotEmpty
                ? Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      child: searchController.text.trim().isEmpty
                          ? RefreshIndicator(
                              onRefresh: () async {
                                if (searchController.text.trim().isEmpty) {
                                  controller.refresh();
                                }
                              },
                              child: _commentListViewBuilder(items),
                            )
                          : _commentListViewBuilder(items),
                    ),
                  )
                : Expanded(
                    child: Center(
                      child: Text("No Results Found"),
                    ),
                  ),
          ],
        );
      },
    );
  }

  ScrollablePositionedList _commentListViewBuilder(
      List<CommentItemModel> items) {
    return ScrollablePositionedList.separated(
      itemScrollController: itemScrollController,
      scrollOffsetController: scrollOffsetController,
      itemPositionsListener: itemPositionsListener,
      scrollOffsetListener: scrollOffsetListener,
      itemBuilder: (context, index) {
        final CommentItemModel item = items[index];
        return CommentTile(
          key: ValueKey(
              '${item.author}/${item.permlink}/${item.created.toIso8601String()}'),
          itemScrollController: itemScrollController,
          isPadded: item.depth != 1 && searchController.text.isEmpty,
          currentUser: widget.appData.username!,
          comment: item,
          index: index,
          searchKey: searchController.text.trim(),
        );
      },
      separatorBuilder: (context, index) {
        bool commentDividerVisibility = true;
        commentDividerVisibility =
            _commentDividerVisibility(index, items, commentDividerVisibility);
        return Visibility(
          visible: commentDividerVisibility,
          child: const Divider(
            height: 10,
            color: Colors.blueGrey,
          ),
        );
      },
      itemCount: items.length,
    );
  }

  bool _commentDividerVisibility(
      int index, List<CommentItemModel> items, bool drawLine) {
    if (index + 1 < items.length) {
      if ((items[index + 1].depth == 1)) {
        drawLine = true;
      } else {
        drawLine = false;
      }
    }
    return drawLine;
  }

  Widget _addCommentButton() {
    return SafeArea(
      child: Selector<CommentController, ViewState>(
        selector: (context, provider) => provider.viewState,
        builder: (context, viewState, child) {
          if (viewState == ViewState.data || viewState == ViewState.empty) {
            return Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10, bottom: 10),
              child: SizedBox(
                height: 35,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(4),
                      ),
                    ),
                  ),
                  onPressed: () => commentPressed(controller),
                  icon: Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Add a Comment",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }

  void commentPressed(CommentController controller) {
    if (widget.appData.username == null) {
      showAdaptiveActionSheet(
        context: context,
        title: const Text('You are not logged in. Please log in to comment.'),
        androidBorderRadius: 30,
        actions: [
          BottomSheetAction(
              title: Text('Log in'),
              leading: Icon(Icons.login),
              onPressed: (c) {
                Navigator.of(c).pop();
                var screen = HiveAuthLoginScreen(appData: widget.appData);
                var route = MaterialPageRoute(builder: (c) => screen);
                Navigator.of(c).push(route);
              }),
        ],
        cancelAction: CancelAction(title: const Text('Cancel')),
      );
      return;
    }
    var screen = HiveCommentDialog(
      author: widget.item.author?.username ?? 'sagarkothari88',
      permlink: widget.item.permlink ?? 'ctbtwcxbbd',
      username: widget.appData.username ?? "",
      hasKey: widget.appData.keychainData?.hasId ?? "",
      hasAuthKey: widget.appData.keychainData?.hasAuthKey ?? "",
      onClose: () {},
      onDone: (newComment) async {
        if (newComment != null) {
          controller.addTopLevelComment(
              newComment, searchController.text.trim());
          int animateToindex = controller.sort == Sort.newest
              ? 0
              : controller.disPlayedItems.length - 1;
          if (searchController.text.isEmpty) {
            _animteToAddedComment(animateToindex);
          } else if (controller.disPlayedItems.contains(newComment)) {
            _animteToAddedComment(animateToindex);
          }
        }
      },
    );
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => screen));
  }

  void _animteToAddedComment(int index) {
    itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: controller,
        builder: (context, child) {
          return Selector<CommentController, ViewState>(
            selector: (_, myType) => myType.viewState,
            builder: (context, state, child) {
              return Scaffold(
                bottomNavigationBar: _addCommentButton(),
                appBar: CommentViewAppbar(
                  state: state,
                  searchKey: searchController,
                  showSearchBar: showSearchBar,
                ),
                body: SafeArea(
                  child: _body(
                    state,
                  ),
                ),
              );
            },
          );
        });
  }

  Widget _body(
    ViewState state,
  ) {
    if (state == ViewState.data) {
      return commentsListView();
    } else if (state == ViewState.empty) {
      return Center(
        child: Text("No comments found"),
      );
    } else if (state == ViewState.error) {
      return Container(
        margin: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Sorry, something went wrong"),
              TextButton(
                  onPressed: () => controller.refresh(), child: Text("Retry"))
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(child: CircularProgressIndicator(value: null)),
            SizedBox(height: 20),
            Text('Loading comments'),
          ],
        ),
      );
    }
  }
}
