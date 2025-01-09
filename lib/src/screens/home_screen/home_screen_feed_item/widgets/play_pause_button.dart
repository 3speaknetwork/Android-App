// import 'package:acela/src/screens/home_screen/home_screen_feed_item/controller/home_feed_video_controller.dart';
// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class PlayPauseButton extends StatelessWidget {
//   const PlayPauseButton({Key? key, required this.betterPlayerController}) : super(key: key);

//   final BetterPlayerController betterPlayerController;

//   @override
//   Widget build(BuildContext context) {
//     bool isInitialized = context
//         .select<HomeFeedVideoController, bool>((value) => value.isInitialized);
//     bool isPaused = context
//         .select<HomeFeedVideoController, bool>((value) => value.isPaused);
//     return Visibility(
//       visible: isInitialized,
//       child: CircleAvatar(
//         backgroundColor: Theme.of(context).primaryColorDark.withOpacity(0.5),
//         child: IconButton(
//           icon: Icon(
//             !isPaused ? Icons.pause : Icons.play_arrow,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             if (isPaused) {
//               betterPlayerController.play();
//             } else {
//               betterPlayerController.pause();
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
