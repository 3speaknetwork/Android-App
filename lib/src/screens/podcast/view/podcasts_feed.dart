import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/models/podcast/trending_podcast_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/podcast/podcast_communicator.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/new_pod_cast_epidose_player.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:acela/src/widgets/retry.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class PodcastFeedScreen extends StatefulWidget {
  const PodcastFeedScreen({
    Key? key,
    required this.appData,
    required this.item,
  });

  final HiveUserData appData;
  final PodCastFeedItem item;

  @override
  State<PodcastFeedScreen> createState() => _PodcastFeedScreenState();
}

class _PodcastFeedScreenState extends State<PodcastFeedScreen> {
  late Future<PodcastEpisodesByFeedResponse> future;

  @override
  void initState() {
    super.initState();
    if (!GetAudioPlayer().audioHandler.isInitiated) {
      GetAudioPlayer().audioHandler.isInitiated = true;
      GetAudioPlayer().audioHandler.play();
    }

    future = loadPodCastEpisode();
  }

  Widget _fullPost(List<PodcastEpisode> items) {
    GetAudioPlayer audioPlayer = GetAudioPlayer();
    audioPlayer.audioHandler.updateQueue([]);
    print(audioPlayer.audioHandler.queue.value.length);
    audioPlayer.audioHandler.addQueueItems(items
        .map((e) => MediaItem(
            id: e.enclosureUrl ?? "",
            title: e.title ?? "",
            artUri: Uri.parse(e.image ?? ""),
            duration: Duration(seconds: e.duration ?? 0)))
        .toList());

    return NewPodcastEpidosePlayer(
      podcastEpisodes: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          leading: CachedImage(
            imageUrl: widget.item.networkImage ?? '',
            imageHeight: 40,
            imageWidth: 40,
          ),
          title: Text(widget.item.title ?? 'No Title'),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RetryScreen(
                  error: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {
                      future = loadPodCastEpisode();
                    });
                  });
            } else if (snapshot.connectionState == ConnectionState.done) {
              var data = snapshot.data as PodcastEpisodesByFeedResponse;
              var list = data.items ?? [];
              if (list.isEmpty) {
                return RetryScreen(
                    error: 'No data found.',
                    onRetry: () {
                      setState(() {
                        future = loadPodCastEpisode();
                      });
                    });
              } else {
                return _fullPost(list);
              }
            } else {
              return LoadingScreen(title: 'Loading', subtitle: 'Please wait..');
            }
          },
        ),
      ),
    );
  }

  Future<PodcastEpisodesByFeedResponse> loadPodCastEpisode() {
    if (widget.item.rssUrl != null) {
      return PodCastCommunicator().getPodcastEpisodesByRss(widget.item.rssUrl!);
    } else {
      return PodCastCommunicator()
          .getPodcastEpisodesByFeedId("${widget.item.id ?? 227573}");
    }
  }
}
