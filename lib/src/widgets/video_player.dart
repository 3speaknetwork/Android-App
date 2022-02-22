import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
// import 'package:acela/src/widgets/controls_overlay.dart';
import 'package:chewie/chewie.dart';

class SPKVideoPlayer extends StatefulWidget {
  const SPKVideoPlayer(
      {Key? key, required this.playUrl, required this.handleFullScreen})
      : super(key: key);
  final String playUrl;
  final Function(bool) handleFullScreen;

  @override
  _SPKVideoPlayerState createState() => _SPKVideoPlayerState();
}

class _SPKVideoPlayerState extends State<SPKVideoPlayer>
    with AutomaticKeepAliveClientMixin<SPKVideoPlayer> {
  // late VideoPlayerController controller;

  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
  }

  @override
  void initState() {
    videoPlayerController = VideoPlayerController.network(widget.playUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
      ..initialize().then((_) {
        setState(() {
          chewieController = ChewieController(
            videoPlayerController: videoPlayerController,
            autoPlay: true,
            looping: false,
          );
        });
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return chewieController == null ? const LoadingScreen() : Chewie(
      controller: chewieController!,
    );
    // return Center(
    //   child: controller.value.isInitialized
    //       ? AspectRatio(
    //           aspectRatio: controller.value.aspectRatio,
    //           child: Stack(
    //             alignment: Alignment.bottomCenter,
    //             children: <Widget>[
    //               VideoPlayer(controller),
    //               ClosedCaption(text: controller.value.caption.text),
    //               ControlsOverlay(
    //                 controller: controller,
    //                 handleFullScreen: (value) {
    //                   widget.handleFullScreen(value);
    //                 },
    //               ),
    //               VideoProgressIndicator(
    //                 controller,
    //                 allowScrubbing: true,
    //                 padding: const EdgeInsets.all(20),
    //               ),
    //             ],
    //           ),
    //         )
    //       : const LoadingScreen(),
    // );
  }
}
