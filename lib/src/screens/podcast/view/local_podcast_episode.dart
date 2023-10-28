import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/widgets/audio_player/new_pod_cast_epidose_player.dart';
import 'package:acela/src/widgets/audio_player/touch_controls.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocalPodcastEpisode extends StatelessWidget {
  const LocalPodcastEpisode({Key? key, required this.appData})
      : super(key: key);
  final HiveUserData appData;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Podcast Episodes'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Offline Episode'),
              Tab(text: 'Liked Episode'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LocalEpisodeListView(isOffline: true),
            LocalEpisodeListView(isOffline: false),
          ],
        ),
      ),
    );
  }
}

class LocalEpisodeListView extends StatelessWidget {
  const LocalEpisodeListView({Key? key, required this.isOffline})
      : super(key: key);

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PodcastController>();
    List<PodcastEpisode> items =
        controller.likedOrOfflinepodcastEpisodes(isOffline: isOffline);
    if (items.isEmpty)
      return Center(
          child: Text(
              "${isOffline ? "Offline" : "Liked"} Podcast Episode is Empty"));
    else
      return ListView.separated(
        itemBuilder: (c, index) {
          PodcastEpisode item = items[index];
          return isOffline
              ? Dismissible(
                  key: Key(item.id.toString()),
                  background: Center(child: Text("Delete")),
                  onDismissed: (direction) {
                    controller.deleteOfflinePodcastEpisode(item);
                  },
                  child: podcastEpisodeListItem(item, context, controller))
              : podcastEpisodeListItem(item, context, controller);
        },
        separatorBuilder: (c, i) => const Divider(height: 0),
        itemCount: items.length,
      );
  }

  ListTile podcastEpisodeListItem(
      PodcastEpisode item, BuildContext context, PodcastController controller) {
    String url = item.enclosureUrl ?? "";
    if (isOffline) {
      url =
          Uri.parse(controller.getOfflineUrl(item.enclosureUrl ?? "", item.id!)).path;
    }
    return ListTile(
      onTap: () {
        GetAudioPlayer audioPlayer = GetAudioPlayer();
        audioPlayer.audioHandler.updateQueue([]);
        audioPlayer.audioHandler.addQueueItem(MediaItem(
            id: url,
            title: item.title ?? "",
            artUri: Uri.parse(item.image ?? ""),
            duration: Duration(seconds: item.duration ?? 0)));
        var screen = Scaffold(
          appBar: AppBar(
            title: ListTile(
              leading: CachedImage(
                imageUrl: item.image ?? '',
                imageHeight: 40,
                imageWidth: 40,
              ),
              title: Text(item.title ?? 'No Title'),
            ),
          ),
          body: SafeArea(
              child: NewPodcastEpidosePlayer(
            podcastEpisodes: [item],
          )),
        );
        var route = MaterialPageRoute(builder: (c) => screen);
        Navigator.of(context).push(route);
      },
      leading: Container(
        height: 30,
        width: 30,
        decoration: BoxDecoration(
            color: Colors.grey,
            image: DecorationImage(
                image: NetworkImage(
                  item.image ?? "",
                ),
                fit: BoxFit.cover)),
      ),
      title: Text(
        item.title ?? '',
        maxLines: 2,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
