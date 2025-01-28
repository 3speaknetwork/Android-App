import 'package:acela/src/screens/upload/video/video_editor/crop_page.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditActionBar extends StatelessWidget
    implements PreferredSizeWidget {
  final double height;
  final VideoEditorController controller;
  final ValueNotifier<bool> isExporting;
  final ValueNotifier<double> exportingProgress;
  final VoidCallback exportVideo;

  const VideoEditActionBar({
    required this.height,
    required this.controller,
    required this.isExporting,
    required this.exportingProgress,
    required this.exportVideo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        height: preferredSize.height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => CropPage(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: isExporting,
                builder: (_, bool export, Widget? child) => AnimatedSize(
                  duration: kThemeAnimationDuration,
                  child: export
                      ? child
                      : PopupMenuButton(
                          tooltip: 'Open export menu',
                          icon: const Icon(Icons.save),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: exportVideo,
                              child: const Text('Export video'),
                            ),
                          ],
                        ),
                ),
                child: ValueListenableBuilder(
                  valueListenable: exportingProgress,
                  builder: (_, double value, __) => Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey.shade50.withOpacity(0.3),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
