import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/screens/podcast/controller/podcast_chapters_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/action_tools.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/screens/podcast/widgets/podcast_player_widgets/podcast_player_intercation_icon_button.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const ControlButtons(this.audioHandler,
      {Key? key,
      required this.showSkipPreviousButtom,
      required this.podcastEpisode,
      required this.positionStream,
      required this.chapterController})
      : super(key: key);

  final bool showSkipPreviousButtom;
  final PodcastEpisode podcastEpisode;
  final Stream<PositionData> positionStream;
  final PodcastChapterController chapterController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isPaused = false;
    Color iconColor = theme.primaryColorLight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: showSkipPreviousButtom,
          child: StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: chapterController.hasPreviousChapter() ||
                          queueState.hasPrevious
                      ? iconColor
                      : iconColor.withOpacity(0.5),
                ),
                onPressed: () {
                  chapterController.jumpToPreviousChapter(queueState.hasPrevious
                      ? audioHandler.skipToPrevious
                      : () {});
                },
              );
            },
          ),
        ),
        StreamBuilder<PositionData>(
          stream: positionStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ??
                PositionData(Duration.zero, Duration.zero, Duration.zero);
            return PodcastPlayerInteractionIconButton(
                size: 35,
                horizontalPadding: 20,
                onPressed: () => goBackTenSeconds(positionData),
                icon: Icons.replay_10,
                color: iconColor);
          },
        ),
        StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, snapshot) {
            final playbackState = snapshot.data;
            final processingState = playbackState?.processingState;
            final playing = playbackState?.playing;
            if (processingState == AudioProcessingState.idle && !isPaused)
              audioHandler.play();
            if (processingState == AudioProcessingState.loading ||
                processingState == AudioProcessingState.buffering) {
              return CircleAvatar(
                radius: 32,
                backgroundColor: theme.primaryColorLight,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.primaryColorDark,
                ),
              );
            } else if (playing != true) {
              return GestureDetector(
                onTap: audioHandler.play,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.primaryColorLight,
                  child: Icon(
                    Icons.play_arrow,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
              );
            } else {
              _continueFromDuration(context);
              return GestureDetector(
                onTap: () {
                  isPaused = !isPaused;
                  audioHandler.pause();
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.primaryColorLight,
                  child: Icon(
                    Icons.pause,
                    size: 35,
                    color: Colors.black,
                  ),
                ),
              );
            }
          },
        ),
        StreamBuilder<PositionData>(
          stream: positionStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ??
                PositionData(Duration.zero, Duration.zero, Duration.zero);
            return PodcastPlayerInteractionIconButton(
                size: 35,
                horizontalPadding: 20,
                onPressed: () => _goForwardTenSeconds(positionData),
                icon: Icons.forward_10,
                color: iconColor);
          },
        ),
        Visibility(
          visible: showSkipPreviousButtom,
          child: StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color:
                      chapterController.hasNextChapter() || queueState.hasNext
                          ? iconColor
                          : iconColor.withOpacity(0.5),
                ),
                onPressed: () {
                  chapterController.jumpToNextChapter(
                      queueState.hasNext ? audioHandler.skipToNext : () {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _continueFromDuration(BuildContext context) {
    final podcastController = context.read<PodcastController>();
    if (podcastController.isDurationContinuing) {
      int? skipToDuration = podcastController.readSavedDurationOfEpisode(
          podcastEpisode.id!, podcastEpisode.enclosureUrl!);
      podcastController.isDurationContinuing = true;
      if (skipToDuration != null) {
        audioHandler.seek(Duration(seconds: skipToDuration));
      }
      podcastController.isDurationContinuing = false;
    }
  }

  void _goForwardTenSeconds(PositionData positionData) {
    chapterController.currentDuration = chapterController.currentDuration + 10;
    chapterController.syncChapters(isInteracted: true, isReduced: false);
    audioHandler.seek(Duration(seconds: positionData.position.inSeconds + 10));
  }

  void goBackTenSeconds(PositionData positionData) {
    if (chapterController.currentDuration - 10 < 0) {
      chapterController.currentDuration = 0;
    } else {
      chapterController.currentDuration =
          chapterController.currentDuration - 10;
    }
    chapterController.syncChapters(isInteracted: true, isReduced: true);
    if (positionData.position.inSeconds > 10) {
      audioHandler
          .seek(Duration(seconds: positionData.position.inSeconds - 10));
    } else {
      audioHandler.seek(Duration(seconds: 0));
    }
  }
}
