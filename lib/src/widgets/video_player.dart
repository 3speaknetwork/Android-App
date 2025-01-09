// // import 'package:video_player/video_player.dart';
// // import 'package:chewie/chewie.dart';


// import 'package:flutter/material.dart';

// import 'package:better_player/better_player.dart';

// class SPKVideoPlayer extends StatefulWidget {
//   const SPKVideoPlayer({Key? key, required this.playUrl}) : super(key: key);
//   final String playUrl;

//   @override
//   _SPKVideoPlayerState createState() => _SPKVideoPlayerState();
// }

// class _SPKVideoPlayerState extends State<SPKVideoPlayer> {
//   late BetterPlayerController _betterPlayerController;

//   @override
//   void initState() {
//     BetterPlayerConfiguration betterPlayerConfiguration =
//     BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         fit: BoxFit.contain,
//         autoPlay: true,
//         fullScreenByDefault: false,
//         controlsConfiguration: BetterPlayerControlsConfiguration(
//           enablePip: true,
//           enableFullscreen: false,
//           enableSkips: true,
//           pipMenuIcon: Icons.picture_in_picture,
//         ),
//         autoDetectFullscreenAspectRatio: false,
//         autoDetectFullscreenDeviceOrientation: false,
//         autoDispose: true,
//         expandToFill: true,
//     );
//     BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       widget.playUrl,
//       videoFormat: BetterPlayerVideoFormat.hls,
//     );
//     _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
//     _betterPlayerController.setupDataSource(dataSource);
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BetterPlayer(
//       controller: _betterPlayerController,
//     );
//   }
// }