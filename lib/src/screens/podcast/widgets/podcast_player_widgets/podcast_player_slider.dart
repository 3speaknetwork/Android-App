import 'dart:developer';

import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/screens/podcast/controller/podcast_chapters_controller.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/action_tools.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/utils/seconds_to_duration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PodcastPlayerSlider extends StatelessWidget {
  const PodcastPlayerSlider(
      {Key? key,
      required this.chapterController,
      required this.audioPlayerHandler,
      required this.currentPodcastEpisodeDuration,
      required this.episode,
      required this.positionDataStream})
      : super(key: key);

  final PodcastChapterController chapterController;
  final AudioPlayerHandler audioPlayerHandler;
  final int? currentPodcastEpisodeDuration;
  final Stream<PositionData> positionDataStream;
  final PodcastEpisode episode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5),
      child: StreamBuilder<PositionData>(
        stream: positionDataStream,
        builder: (context, snapshot) {
          final positionData = snapshot.data ??
              PositionData(Duration.zero, Duration.zero, Duration.zero);
          // writeCurrentDurationLocal(context, positionData.position.inSeconds);
          var duration = currentPodcastEpisodeDuration?.toDouble() ?? 0.0;
          var pending = duration - positionData.position.inSeconds;
          var pendingText = "${Utilities.formatTime(pending.toInt())}";
          var leadingText =
              "${Utilities.formatTime(positionData.position.inSeconds)}";
          chapterController.setDurationData(positionData);
          chapterController.syncChapters();
          return Row(
            children: [
              Text(leadingText),
              Expanded(
                child: SeekBar(
                  duration: positionData.duration,
                  position: positionData.position,
                  onChanged: _onSlideChange,
                  onChangeEnd: (newPosition) {
                    audioPlayerHandler.seek(newPosition);
                  },
                ),
              ),
              Text(pendingText),
            ],
          );
        },
      ),
    );
  }

  void writeCurrentDurationLocal(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: 10)).then((value) {
      if (seconds > 0) {
        log('writed');
        context.read<PodcastController>().writeDurationOfEpisode(
            episode.id!, episode.enclosureUrl!, seconds);
      }
    });
  }

  void _onSlideChange(Duration newPosition) {
    chapterController.syncChapters(
        isInteracted: true,
        isReduced: newPosition.inSeconds < chapterController.currentDuration);
    chapterController.currentDuration = newPosition.inSeconds;
    audioPlayerHandler.seek(newPosition);
  }
}
