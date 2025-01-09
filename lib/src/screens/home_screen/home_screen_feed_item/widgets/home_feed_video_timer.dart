// import 'package:acela/src/screens/home_screen/home_screen_feed_item/controller/home_feed_video_controller.dart';
// import 'package:acela/src/utils/seconds_to_duration.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class HomeFeedVideoTimer extends StatelessWidget {
//   const HomeFeedVideoTimer({Key? key, required this.totalDuration})
//       : super(key: key);

//   final double totalDuration;

//   @override
//   Widget build(BuildContext context) {
//     bool isInitialized = context
//         .select<HomeFeedVideoController, bool>((value) => value.isInitialized);
//     Duration? currentDuration =
//         context.select<HomeFeedVideoController, Duration?>(
//             (value) => value.currentDuration);
//     Duration? totalDuration =
//         context.select<HomeFeedVideoController, Duration?>(
//             (value) => value.totalDuration);
//     Duration? defaultDuration = Utilities.doubleToDuration(this.totalDuration);
//     return AnimatedPadding(
//       duration: const Duration(milliseconds: 150),
//       padding: EdgeInsets.only(bottom: isInitialized ? 8 : 0),
//       child: Container(
//           padding: EdgeInsets.symmetric(
//             vertical: 2,
//             horizontal: 4,
//           ),
//           decoration: BoxDecoration(
//             color: Theme.of(context).primaryColorDark.withOpacity(0.8),
//             borderRadius: BorderRadius.all(
//               Radius.circular(4),
//             ),
//           ),
//           child: Text(
//             isInitialized
//                 ? remainingDuration(
//                     totalDuration ?? defaultDuration, currentDuration)
//                 : remainingDuration(defaultDuration, null),
//             style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
//           )),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     int hours = duration.inHours;
//     int minutes = (duration.inMinutes % 60);
//     int seconds = (duration.inSeconds % 60);

//     String formattedDuration =
//         '${hours > 0 ? hours.toString().padLeft(2, '0') + ':' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

//     return formattedDuration;
//   }

//   String remainingDuration(Duration totalDuration, Duration? currentDuration) {
//     Duration remainingTime =
//         totalDuration - (currentDuration ?? Duration(milliseconds: 0));
//     String formattedRemainingTime = _formatDuration(remainingTime);
//     return formattedRemainingTime;
//   }
// }
