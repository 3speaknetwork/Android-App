import 'package:acela/src/screens/video_details_screen/comment/controller/comment_controller.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Menu extends StatelessWidget {
  const Menu({
    Key? key,
    required this.searchKey,
  }) : super(
          key: key,
        );

  final TextEditingController searchKey;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommentController>();
    return PopupMenuButton(
      constraints: BoxConstraints(),
      padding: EdgeInsets.zero,
      tooltip: "Sort",
      icon: Icon(
        Icons.filter_list,
      ),
      itemBuilder: (context) {
        return <PopupMenuEntry>[
          PopupMenuItem(
            height: 40,
            padding: const EdgeInsets.only(left: 10),
            onTap: () => controller.onSort(Sort.newest, searchKey.text.trim()),
            child: Text(
              'Newest',
              style: TextStyle(
                  color: controller.sort == Sort.newest ? Colors.blue : null),
            ),
          ),
          PopupMenuItem(
            height: 40,
            padding: const EdgeInsets.only(left: 10),
            onTap: () => controller.onSort(Sort.oldest, searchKey.text.trim()),
            child: Text(
              'Oldest',
              style: TextStyle(
                  color: controller.sort == Sort.oldest ? Colors.blue : null),
            ),
          )
        ];
      },
    );
  }
}
