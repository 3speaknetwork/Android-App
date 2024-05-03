import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/new_pod_cast_epidose_player.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';

class PodcastPlayerController extends ChangeNotifier {
  final MiniplayerController miniplayerController = MiniplayerController();
  List<PodcastEpisode> episodes = [];
  int index = 0;

  void openPodcastPlayer(int index, {bool playOnMiniPlayer = true}) {
    this.index = index;
    notifyListeners();
    if (playOnMiniPlayer) {
      miniplayerController.animateToHeight(state: PanelState.MAX);
    }
  }

  void setData(List<PodcastEpisode> episodes, int index,
      {bool playOnMiniPlayer = true}) {
    this.episodes = episodes;
    openPodcastPlayer(index, playOnMiniPlayer: playOnMiniPlayer);
  }

  Future<void> _addEpisodesToQueue(List<PodcastEpisode> items) async {
    GetAudioPlayer audioPlayer = GetAudioPlayer();
    await audioPlayer.audioHandler.updateQueue([]);
    print(audioPlayer.audioHandler.queue.value.length);
    await audioPlayer.audioHandler.addQueueItems(items
        .map((e) => MediaItem(
            id: e.enclosureUrl ?? "",
            title: e.title ?? "",
            artUri: Uri.parse(e.image ?? ""),
            duration: Duration(seconds: e.duration ?? 0)))
        .toList());
  }

  void _initiatePlay(BuildContext context, List<PodcastEpisode> episodes,
      int index, bool playOnMiniPlayer) {
    if (!GetAudioPlayer().audioHandler.isInitiated) {
      GetAudioPlayer().audioHandler.isInitiated = true;
    }
    GetAudioPlayer().audioHandler.play();
    setData(episodes, index, playOnMiniPlayer: playOnMiniPlayer);
    if (!playOnMiniPlayer) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NewPodcastEpidosePlayer(
              dragValue: 1,
              currentPodcastIndex: index,
              podcastEpisodes: episodes),
        ),
      );
    }
  }

  void onTapEpisode(int index, BuildContext context,
      List<PodcastEpisode> episodes, bool playOnMiniPlayer) async {
    await _addEpisodesToQueue(episodes);
    GetAudioPlayer().audioHandler.skipToQueueItem(index);
    _initiatePlay(context, episodes, index, playOnMiniPlayer);
  }

  void onDefaultPlay(BuildContext context,List<PodcastEpisode> episodes, bool playOnMiniPlayer) async {
    await _addEpisodesToQueue(episodes);
    _initiatePlay(context, episodes, 0, playOnMiniPlayer);
  }
}
