import 'dart:developer';
import 'dart:io';

import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/podcast/controller/podcast_controller.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/new_pod_cast_epidose_player.dart';
import 'package:acela/src/screens/podcast/widgets/audio_player/audio_player_core_controls.dart';
import 'package:acela/src/widgets/cached_image.dart';
import 'package:acela/src/widgets/confirmation_dialog.dart';
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
              Tab(text: 'Bookmarked Episode'),
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
          log(item.image!);
          return Dismissible(
              key: Key(item.id.toString()),
              background: Center(child: Text("Delete")),
              confirmDismiss: (direction) async {
                if (isOffline) {
                  bool delete = false;
                  await showDialog(
                    context: context,
                    builder: (context) => ConfirmationDialog(
                        title: "Delete",
                        content:
                            "Are you sure you want to delete this episode ",
                        onConfirm: () {
                          delete = true;
                        }),
                  ).whenComplete(() => null);
                  return Future.value(delete);
                } else {
                  return Future.value(true);
                }
              },
              onDismissed: (direction) {
                if (isOffline) {
                  controller.deleteOfflinePodcastEpisode(item);
                } else {
                  controller.storeLikedPodcastEpisodeLocally(item,
                      forceRemove: true);
                }
              },
              child: podcastEpisodeListItem(item, context, controller));
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
          Uri.parse(controller.getOfflineUrl(item.enclosureUrl ?? "", item.id!))
              .path;
      item.enclosureUrl = '$url';
    }
    return ListTile(
        onTap: () {
          GetAudioPlayer audioPlayer = GetAudioPlayer();
          audioPlayer.audioHandler.updateQueue([]);
          audioPlayer.audioHandler.addQueueItem(
            MediaItem(
              id: url,
              title: item.title ?? "",
              artUri: Uri.parse(item.image ?? ""),
              duration: Duration(seconds: item.duration ?? 0),
            ),
          );
          if (!GetAudioPlayer().audioHandler.isInitiated) {
            GetAudioPlayer().audioHandler.isInitiated = true;
          }
          GetAudioPlayer().audioHandler.play();
          var screen = NewPodcastEpidosePlayer(
            currentPodcastIndex: 0,
            podcastEpisodes: [item],
          );
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(context).push(route);
        },
        leading: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
              color: Colors.grey,
              image: (isOffline && !item.image!.startsWith('http'))
                  ? DecorationImage(
                      image: FileImage(File(item.image!)), fit: BoxFit.cover)
                  : DecorationImage(
                      image: NetworkImage(
                        item.image ?? "",
                      ),
                    )),
        ),
        title: Text(
          item.title ?? '',
          maxLines: 2,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        trailing: fileSizeWidget(item.enclosureUrl));
  }

  Widget? fileSizeWidget(String? enclosureUrl) {
    if (enclosureUrl == null) return null;
    try {
      return isOffline
          ? Text(formatBytes(File(enclosureUrl).lengthSync()))
          : null;
    } catch (e) {
      return null;
    }
  }

  String formatBytes(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    int i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
