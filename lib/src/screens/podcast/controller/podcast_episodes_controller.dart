import 'package:acela/src/models/podcast/podcast_episodes.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:acela/src/utils/podcast/podcast_communicator.dart';
import 'package:flutter/material.dart';

class PodcastEpisodesController extends ChangeNotifier {
  List<PodcastEpisode> items = [];
  ViewState viewState = ViewState.loading;
  final bool isRss;
  final String id;

  PodcastEpisodesController({required this.isRss, required this.id}) {
    _init();
  }

  void _init() async {
    try {
      PodcastEpisodesByFeedResponse response = await fetchEpisodes();
      if (response.items != null && response.items!.isNotEmpty) {
        items = response.items!;
        viewState = ViewState.data;
      } else {
        viewState = ViewState.empty;
      }
      notifyListeners();
    } catch (e) {
      viewState = ViewState.error;
      notifyListeners();
    }
  }

  Future<PodcastEpisodesByFeedResponse> fetchEpisodes() async {
    if (isRss) {
      return await PodCastCommunicator().getPodcastEpisodesByRss(id);
    } else {
      return await PodCastCommunicator().getPodcastEpisodesByFeedId(id);
    }
  }

 

  void refresh() {
    viewState = ViewState.loading;
    notifyListeners();
    _init();
  }
}
