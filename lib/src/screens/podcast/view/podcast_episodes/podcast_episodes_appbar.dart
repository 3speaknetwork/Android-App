import 'package:acela/src/widgets/cached_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class PodcastEpisodesAppbar extends StatefulWidget
    implements PreferredSizeWidget {
  final ScrollController scrollController;
  final String? image;
  final String? title;

  PodcastEpisodesAppbar({
    required this.scrollController,
    required this.image,
    required this.title,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  State<PodcastEpisodesAppbar> createState() => _PodcastEpisodesAppbarState();
}

class _PodcastEpisodesAppbarState extends State<PodcastEpisodesAppbar> {
  ValueNotifier<double> offset = ValueNotifier(0);

  @override
  void initState() {
    widget.scrollController.addListener(scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(scrollListener);
    super.dispose();
  }

  void scrollListener() {
    offset.value = widget.scrollController.offset;
    offset.value = widget.scrollController.offset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.primaryColorDark,
      leadingWidth: 30,
      title: ValueListenableBuilder<double>(
          valueListenable: offset,
          builder: (context, value, child) {
            return value > 130
                ? ListTile(
                    leading: CachedImage(
                      imageUrl: widget.image ?? '',
                      imageHeight: 35,
                      imageWidth: 35,
                    ),
                    title: AutoSizeText(
                      widget.title ?? 'No Title',
                      maxLines: 1,
                      maxFontSize: 14,
                      minFontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Text(
                    "Podcast Episodes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  );
          }),
    );
  }
}
