import 'package:acela/src/screens/report/widgets/content_dialog_template.dart';
import 'package:flutter/material.dart';

class ResponsiveScrollDialog extends StatelessWidget {
  const ResponsiveScrollDialog(
      {super.key,
      required this.title,
      required this.content,
      this.maxWidth,
      this.width});

  final String title;
  final Widget? content;
  final double? maxWidth;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ContentDialogTemplate(
      title: title,
      content: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: maxWidth ?? 400, maxHeight: screenHeight),
        child: SizedBox(
          width: width ?? 30,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20), child: content),
        ),
      ),
    );
  }
}
