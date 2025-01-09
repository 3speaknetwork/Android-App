// import 'package:acela/src/global_provider/video_setting_provider.dart';
// import 'package:better_player/better_player.dart';
// import 'package:flutter/material.dart';

// class HomeFeedVideoController extends ChangeNotifier {
//   Duration? currentDuration;
//   Duration? totalDuration;
//   bool skippedToInitialDuartion = false;
//   bool isInitialized = false;
//   bool isUserOnAnotherScreen = false;
//   bool isPaused = false;

//   void videoEventListener(
//       BetterPlayerController? betterPlayerController, BetterPlayerEvent event) {

//     if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen &&
//         !betterPlayerController!.videoPlayerController!.value.isPlaying &&
//         !isUserOnAnotherScreen) {
//       changeControlsVisibility(betterPlayerController, false);
//     }
//   }

//   void didPopFullScreen(BetterPlayerController betterPlayerController) {
//     if (!betterPlayerController.videoPlayerController!.value.isPlaying &&
//         !isUserOnAnotherScreen) {
//       changeControlsVisibility(betterPlayerController, false);
//     }
//   }

//   void videoPlayerListener(BetterPlayerController? betterPlayerController,
//       VideoSettingProvider videoSettingProvider) {
//     if (betterPlayerController != null &&
//         betterPlayerController.videoPlayerController != null &&
//         betterPlayerController.videoPlayerController!.value.initialized) {
//       if (!isInitialized) {
//         isInitialized = true;
//       }
//       if (!betterPlayerController.isFullScreen) {
//         if (betterPlayerController.controlsEnabled && !isUserOnAnotherScreen) {
//           changeControlsVisibility(betterPlayerController, false);
//         }
//       }
//       if (betterPlayerController.videoPlayerController!.value.isPlaying &&
//           isPaused) {
//         isPaused = false;
//       } else if (!betterPlayerController
//               .videoPlayerController!.value.isPlaying &&
//           !isPaused) {
//         isPaused = true;
//       }
//       if (totalDuration == null) {
//         totalDuration =
//             betterPlayerController.videoPlayerController!.value.duration!;
//       }
//       if (!skippedToInitialDuartion) {
//         skippedToInitialDuartion = true;
//         if (currentDuration != null) {
//           Duration totalDuration =
//               betterPlayerController.videoPlayerController!.value.duration!;
//           if (totalDuration != currentDuration) {
//             betterPlayerController.seekTo(currentDuration!).then((value) =>
//                 betterPlayerController.videoPlayerController!.play());
//           }
//         }
//       }
//       currentDuration =
//           betterPlayerController.videoPlayerController!.value.position;
//       WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//         notifyListeners();
//       });
//       if (betterPlayerController.videoPlayerController!.value.volume == 0.0 &&
//           !videoSettingProvider.isMuted) {
//         videoSettingProvider.changeMuteStatus(true);
//       } else if (betterPlayerController.videoPlayerController!.value.volume !=
//               0.0 &&
//           videoSettingProvider.isMuted) {
//         videoSettingProvider.changeMuteStatus(false);
//       }
//     }
//   }

//   void changeControlsVisibility(
//       BetterPlayerController betterPlayerController, bool showControls) {
//     betterPlayerController.setControlsAlwaysVisible(showControls);
//     betterPlayerController.setControlsEnabled(showControls);
//     betterPlayerController.setControlsVisibility(showControls);
//   }

//   void reset() {
//     isInitialized = false;
//     if (isUserOnAnotherScreen) {
//       isUserOnAnotherScreen = false;
//     }
//     notifyListeners();
//   }
// }
