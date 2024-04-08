import 'package:acela/src/screens/video_details_screen/comment/controller/comment_controller.dart';
import 'package:acela/src/screens/video_details_screen/comment/menu.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentViewAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CommentViewAppbar(
      {Key? key, required this.state, required this.showSearchBar, required this.searchKey})
      : super(key: key);

  final ViewState state;
  final ValueNotifier<bool> showSearchBar;
  final TextEditingController searchKey;

  @override
  Widget build(BuildContext context) {
    int numberOfComments = context
        .select<CommentController, int>((value) => value.disPlayedItems.length);
    return AppBar(
      title: Text(
          'Comments${state != ViewState.loading ? ' ($numberOfComments)' : ''}'),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: showSearchBar,
          builder: (context, showSearchButton, child) {
            return Visibility(
                visible: numberOfComments != 0 && !showSearchButton,
                child: child!);
          },
          child: IconButton(
            onPressed: () {
              showSearchBar.value = true;
            },
            icon: Icon(Icons.search),
          ),
        ),
        Menu(
          searchKey: searchKey,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
