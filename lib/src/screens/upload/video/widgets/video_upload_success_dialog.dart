import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class VideoUploadSucessDialog extends StatefulWidget {
  const VideoUploadSucessDialog({
    Key? key,
  }) : super(key: key);

  @override
  State<VideoUploadSucessDialog> createState() =>
      _VideoUploadSucessDialogState();
}

class _VideoUploadSucessDialogState extends State<VideoUploadSucessDialog> {
  late Timer colorChangeTimer;
  late Timer enableButtonTimer;
  int colorIndex = 0;
  Random random = Random();
  bool enableButton = false;

  List<Color> colors = [
    Colors.red,
    Colors.tealAccent,
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.yellow,
    Colors.brown,
    Colors.lightGreenAccent,
    Colors.lime,
    Colors.cyan,
    Colors.amber,
    Colors.redAccent
  ];

  @override
  void initState() {
    super.initState();

    _init();
  }

  void _init() async {
    colorChangeTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          colorIndex = random.nextInt(5);
        });
      }
    });
    enableButtonTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          enableButton = true;
          enableButtonTimer.cancel();
        });
      }
    });
  }

  @override
  void dispose() {
    colorChangeTimer.cancel();
    enableButtonTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (enableButton) return true;
        return false;
      },
      child: AlertDialog(
        title: Text("🎉 Upload Complete 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "✅ Your Video is in-process.\n✅ Video has be added to encoding queue.\n⏳Video will be processed."),
            SizedBox(
              height: 10,
            ),
            Text(
              "🚨 Your Video will be automatically published 🚨",
              style: TextStyle(
                  color: colors[colorIndex],
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            )
          ],
        ),
        actions: [
          Stack(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor),
                child: Text("AutoPublish"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Positioned.fill(
                top: 4,
                bottom: 4,
                child: Visibility(
                  visible: !enableButton,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black12.withOpacity(0.5),
                        borderRadius: BorderRadius.all(Radius.circular(40))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
