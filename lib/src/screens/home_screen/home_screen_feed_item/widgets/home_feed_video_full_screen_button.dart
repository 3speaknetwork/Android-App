// import 'package:acela/src/models/user_stream/hive_user_stream.dart';
// import 'package:acela/src/screens/home_screen/home_screen_feed_item/controller/home_feed_video_controller.dart';
// import 'package:acela/src/utils/graphql/models/trending_feed_response.dart';
// import 'package:better_player/better_player.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';

// class HomeFeedVideoFullScreenButton extends StatelessWidget {
//   const HomeFeedVideoFullScreenButton(
//       {Key? key,
//       required this.betterPlayerController,
//       required this.item,
//       required this.appData})
//       : super(key: key);

//   final BetterPlayerController betterPlayerController;
//   final GQLFeedItem item;
//   final HiveUserData appData;

//   @override
//   Widget build(BuildContext context) {
//     bool isInitialized = context
//         .select<HomeFeedVideoController, bool>((value) => value.isInitialized);
//     return Visibility(
//       visible: isInitialized,
//       child: CircleAvatar(
//         backgroundColor: Theme.of(context).primaryColorDark.withOpacity(0.5),
//         child: IconButton(
//             onPressed: () {
//               if (defaultTargetPlatform == TargetPlatform.android) {
//                 context
//                     .read<HomeFeedVideoController>()
//                     .changeControlsVisibility(betterPlayerController, true);
//                 betterPlayerController.enterFullScreen();
//               } else {
//                 fullscreenTapped();
//               }
//             },
//             icon: Icon(
//               Icons.fullscreen,
//               color: Colors.white,
//             )),
//       ),
//     );
//   }

//   void fullscreenTapped() async {
//     var position = await betterPlayerController.videoPlayerController?.position;
//     var seconds = position?.inSeconds;
//     if (seconds == null) return;
//     debugPrint('position is $position');
//     const platform = MethodChannel('com.example.acela/auth');
//     await platform.invokeMethod('playFullscreen', {
//       'url': item.videoV2M3U8(appData),
//       'seconds': seconds,
//     });
//   }
// }
