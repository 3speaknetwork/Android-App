import 'package:flutter/material.dart';

class ContentDialogTemplate extends StatelessWidget {
  const ContentDialogTemplate({
    super.key,
    required this.title,
    required this.content,
    this.maxWidth,
  });

  final String title;
  final Widget? content;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.cancel))
          ],
        ),
        content: content);
  }
}
