import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class PublishFab extends StatefulWidget {
  final VoidCallback onPublishNow;
  final VoidCallback onPublishLater;
  final VoidCallback onSchedulePublish;
  final bool isDeviceEncode;

  const PublishFab(
      {Key? key,
      required this.onPublishNow,
      required this.onPublishLater,
      required this.isDeviceEncode,
      required this.onSchedulePublish})
      : super(key: key);

  @override
  State<PublishFab> createState() => _PublishFabState();
}

class _PublishFabState extends State<PublishFab> {
  final _key = GlobalKey<ExpandableFabState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ExpandableFab(
          key: _key,
          distance: 60.0,
          openButtonBuilder:
              DefaultFloatingActionButtonBuilder(child: Icon(Icons.publish)),
          type: ExpandableFabType.up,
          overlayStyle: ExpandableFabOverlayStyle(
              color: Theme.of(context).primaryColorDark.withOpacity(0.6)),
          children: [
            if (widget.isDeviceEncode)
              _item(theme, "Schedule Publish", Icons.schedule,
                  widget.onSchedulePublish),
            if (widget.isDeviceEncode)
              _item(theme, "Publish later", Icons.hourglass_bottom,
                  widget.onPublishLater),
            _item(theme, "Publish Now", Icons.publish, widget.onPublishNow),
          ],
        ),
      ],
    );
  }

  Row _item(ThemeData theme, String label, IconData icon, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade600),
          child: Text(
            label,
            style: theme.textTheme.titleMedium,
          ),
        ),
        SizedBox(width: 20),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: () {
            _key.currentState?.toggle();
            onTap();
          },
          tooltip: label,
          child: Icon(icon),
        ),
      ],
    );
  }
}
