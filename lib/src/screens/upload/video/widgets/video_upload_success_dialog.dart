import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class VideoUploadSucessDialog extends StatefulWidget {
  const VideoUploadSucessDialog({
    Key? key,
    required this.hasPostingAuthority,
  }) : super(key: key);

  final bool hasPostingAuthority;

  @override
  State<VideoUploadSucessDialog> createState() =>
      _VideoUploadSucessDialogState();
}

class _VideoUploadSucessDialogState extends State<VideoUploadSucessDialog> {
  late Timer colorChangeTimer;
  late Timer enableButtonTimer;
  late Timer valueTimer;
  int colorIndex = 0;
  int timerCount = 5;
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
    valueTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          timerCount--;
          if (timerCount == 0) {
            valueTimer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    colorChangeTimer.cancel();
    enableButtonTimer.cancel();
    valueTimer.cancel();
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
              widget.hasPostingAuthority
                  ? "🚨 Your Video will be automatically published 🚨"
                  : "🚨 You will have to publish from my account after it is processed. It will NOT be published automatically. 🚨 ",
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
                child: Text(
                    "${widget.hasPostingAuthority ? "AutoPublish" : "Okay. I will"} ${timerCount != 0 ? timerCount : ""}"),
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
