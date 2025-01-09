
// import 'package:acela/src/models/user_stream/hive_user_stream.dart';
// import 'package:acela/src/models/video_details_model/video_details.dart';
// import 'package:acela/src/utils/communicator.dart';
// import 'package:acela/src/widgets/loading_screen.dart';
// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';

// class VideoPreviewScreen extends StatefulWidget {
//   const VideoPreviewScreen({
//     Key? key,
//     required this.item,
//     required this.data,
//   }) : super(key: key);
//   final VideoDetails item;
//   final HiveUserData data;

//   @override
//   State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
// }

// class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
//   late BetterPlayerController _betterPlayerController;

//   void setupVideo(String url, double ratio) {
//     BetterPlayerConfiguration betterPlayerConfiguration =
//         BetterPlayerConfiguration(
//       aspectRatio: ratio,
//       fit: BoxFit.contain,
//       autoPlay: true,
//       fullScreenByDefault: false,
//       controlsConfiguration: BetterPlayerControlsConfiguration(
//         enablePip: false,
//         enableFullscreen: false,
//         enableSkips: true,
//       ),
//       autoDetectFullscreenAspectRatio: false,
//       autoDetectFullscreenDeviceOrientation: false,
//       autoDispose: true,
//       expandToFill: true,
//       allowedScreenSleep: false,
//     );
//     BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       widget.item.videoV2M3U8(widget.data),
//       videoFormat: BetterPlayerVideoFormat.hls,
//     );
//     _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
//     _betterPlayerController.setupDataSource(dataSource);
//   }

//   Widget container(String title, Widget body) {
//     return Scaffold(
//       body: body,
//       appBar: AppBar(
//         title: Text(title),
//       ),
//     );
//   }

//   Widget _futureForLoadingRatio() {
//     return FutureBuilder(
//       future:
//           Communicator().getAspectRatio(widget.item.videoV2M3U8(widget.data)),
//       builder: (builder, snapshot) {
//         if (snapshot.hasError) {
//           String text =
//               'Something went wrong while loading video information - ${snapshot.error?.toString() ?? ""}';
//           return container('Video Preview', Text(text));
//         } else if (snapshot.hasData &&
//             snapshot.connectionState == ConnectionState.done) {
//           var videoSize = snapshot.data as VideoSize;
//           setupVideo(
//             widget.item.getVideoUrl(widget.data),
//             videoSize.height / videoSize.width,
//           );
//           return Scaffold(
//             appBar: AppBar(
//               title: Text('Video Preview'),
//             ),
//             body: SafeArea(
//               child: SizedBox(
//                 height: double.infinity,
//                 width: double.infinity,
//                 child: BetterPlayer(
//                   controller: _betterPlayerController,
//                 ),
//               ),
//             ),
//           );
//         } else {
//           return container(
//             'Video Preview',
//             const LoadingScreen(
//               title: 'Loading Data',
//               subtitle: 'Please wait',
//             ),
//           );
//         }
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _futureForLoadingRatio();
//   }
// }
