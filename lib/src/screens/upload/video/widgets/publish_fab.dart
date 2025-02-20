import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class PublishFab extends StatefulWidget {
  final VoidCallback onPublishNow;
  final VoidCallback onPublishLater;
  final bool isDeviceEncode;

  const PublishFab(
      {Key? key,
      required this.onPublishNow,
      required this.onPublishLater,
      required this.isDeviceEncode})
      : super(key: key);

  @override
  State<PublishFab> createState() => _PublishFabState();
}

class _PublishFabState extends State<PublishFab> {
  final _key = GlobalKey<ExpandableFabState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpandableFab(
      key: _key,
      distance: 60.0,
      openButtonBuilder:
          DefaultFloatingActionButtonBuilder(child: Icon(Icons.publish)),
      type: ExpandableFabType.up,
      overlayStyle: ExpandableFabOverlayStyle(
          color: Theme.of(context).primaryColorDark.withOpacity(0.6)),
      children: [
        if (widget.isDeviceEncode)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Publish later',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: "publish_later",
                onPressed: widget.onPublishLater,
                tooltip: "Publish Later",
                child: const Icon(Icons.hourglass_bottom),
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Publish Now',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(width: 20),
            FloatingActionButton.small(
              heroTag: "publish_now",
              onPressed: widget.onPublishNow,
              tooltip: "Publish Now",
              child: const Icon(Icons.publish),
            ),
          ],
        ),
      ],
    );
  }
}
