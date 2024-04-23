import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

class GetAudioPlayer {
  GetAudioPlayer._();

  late AudioPlayerHandler audioHandler;

  static final GetAudioPlayer _instance = GetAudioPlayer._();

  factory GetAudioPlayer() {
    return _instance;
  }
}

class QueueState {
  static const QueueState empty =
      QueueState([], 0, [], AudioServiceRepeatMode.none);

  final List<MediaItem> queue;
  final int? queueIndex;
  final List<int>? shuffleIndices;
  final AudioServiceRepeatMode repeatMode;

  const QueueState(
      this.queue, this.queueIndex, this.shuffleIndices, this.repeatMode);

  bool get hasPrevious =>
      repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioServiceRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}

/// An [AudioHandler] for playing a list of podcast episodes.
///
/// This class exposes the interface and not the implementation.
abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;

  VideoPlayerController? videoPlayerController;
  ValueNotifier<double?> aspectRatioNotifier = ValueNotifier(null);

  void setUpVideoController(
    String url,
  );

  Future<int> currentPosition();

  void disposeVideoController();

  bool isVideo = false;

   bool isInitiated = false;

  bool shouldPlayVideo();
}

/// The implementation of [AudioPlayerHandler].
///
/// This handler is backed by a just_audio player. The player's effective
/// sequence is mapped onto the handler's queue, and the player's state is
/// mapped onto the handler's state.
class AudioPlayerHandlerImpl extends BaseAudioHandler
    with SeekHandler
    implements AudioPlayerHandler {
  // ignore: close_sinks
  final BehaviorSubject<List<MediaItem>> _recentSubject =
      BehaviorSubject.seeded(<MediaItem>[]);
  final _mediaLibrary = MediaLibrary();
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  @override
  final BehaviorSubject<double> volume = BehaviorSubject.seeded(1.0);
  @override
  final BehaviorSubject<double> speed = BehaviorSubject.seeded(1.0);
  final _mediaItemExpando = Expando<MediaItem>();
  bool isVideo = false;
  bool isInitiated = false;

  VideoPlayerController? videoPlayerController;
  ValueNotifier<double?> aspectRatioNotifier = ValueNotifier(null);

  @override
  bool shouldPlayVideo() {
    return isVideo && videoPlayerController != null;
  }

  void setUpVideoController(
    String url,
  ) {
    disposeVideoController();
    if (url.startsWith("http")) {
      this.videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(url),
          videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true))
        ..initialize();
    } else {
      this.videoPlayerController = VideoPlayerController.file(File(url),
          videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true))
        ..initialize();
    }
    videoPlayerController!.addListener(() {
      aspectRatioNotifier.value = videoPlayerController!.value.aspectRatio;
      _broadcastState(_player.playbackEvent);
    });
  }

  void disposeVideoController() {
    if (videoPlayerController != null) {
      aspectRatioNotifier.value = null;
      videoPlayerController!.seekTo(Duration.zero);
      videoPlayerController!.removeListener(() {
        _broadcastState(_player.playbackEvent);
      });
      videoPlayerController!.dispose();
    }
  }

  /// A stream of the current effective sequence from just_audio.
  Stream<List<IndexedAudioSource>> get _effectiveSequence => Rx.combineLatest3<
              List<IndexedAudioSource>?,
              List<int>?,
              bool,
              List<IndexedAudioSource>?>(_player.sequenceStream,
          _player.shuffleIndicesStream, _player.shuffleModeEnabledStream,
          (sequence, shuffleIndices, shuffleModeEnabled) {
        if (sequence == null) return [];
        if (!shuffleModeEnabled) return sequence;
        if (shuffleIndices == null) return null;
        if (shuffleIndices.length != sequence.length) return null;
        return shuffleIndices.map((i) => sequence[i]).toList();
      }).whereType<List<IndexedAudioSource>>();

  /// Computes the effective queue index taking shuffle mode into account.
  int? getQueueIndex(
      int? currentIndex, bool shuffleModeEnabled, List<int>? shuffleIndices) {
    final effectiveIndices = _player.effectiveIndices ?? [];
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }
    return (shuffleModeEnabled &&
            ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  @override
  Stream<QueueState> get queueState =>
      Rx.combineLatest3<List<MediaItem>, PlaybackState, List<int>, QueueState>(
          queue,
          playbackState,
          _player.shuffleIndicesStream.whereType<List<int>>(),
          (queue, playbackState, shuffleIndices) => QueueState(
                queue,
                playbackState.queueIndex,
                playbackState.shuffleMode == AudioServiceShuffleMode.all
                    ? shuffleIndices
                    : null,
                playbackState.repeatMode,
              )).where((state) =>
          state.shuffleIndices == null ||
          state.queue.length == state.shuffleIndices!.length);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed.add(speed);
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume.add(volume);
    await _player.setVolume(volume);
  }

  AudioPlayerHandlerImpl() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Broadcast speed changes. Debounce so that we don't flood the notification
    // with updates.
    // Load and broadcast the initial queue
    await updateQueue(_mediaLibrary.items[MediaLibrary.albumsRootId]!);
    // For Android 11, record the most recent item so it can be resumed.
    mediaItem
        .whereType<MediaItem>()
        .listen((item) => _recentSubject.add([item]));
    // Broadcast media item changes.
    Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
        _player.currentIndexStream,
        queue,
        _player.shuffleModeEnabledStream,
        _player.shuffleIndicesStream,
        (index, queue, shuffleModeEnabled, shuffleIndices) {
      final queueIndex =
          getQueueIndex(index, shuffleModeEnabled, shuffleIndices);
      return (queueIndex != null && queueIndex < queue.length)
          ? queue[queueIndex]
          : null;
    }).whereType<MediaItem>().distinct().listen(mediaItem.add);
    // Propagate all events from the audio player to AudioService clients.
    _player.playbackEventStream.listen(_broadcastState);
    _player.shuffleModeEnabledStream
        .listen((enabled) => _broadcastState(_player.playbackEvent));
    // In this example, the service stops when reaching the end.
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop();
        _player.seek(Duration.zero, index: 0);
      }
    });
    // Broadcast the current queue.
    _effectiveSequence
        .map((sequence) =>
            sequence.map((source) => _mediaItemExpando[source]!).toList())
        .pipe(queue);
    // Load the playlist.
    _playlist.addAll(queue.value.map(_itemToSource).toList());
    await _player.setAudioSource(_playlist, preload: false);
  }

  AudioSource _itemToSource(MediaItem mediaItem) {
    if (mediaItem.id.startsWith("http")) {
      final audioSource = AudioSource.uri(Uri.parse(mediaItem.id));
      _mediaItemExpando[audioSource] = mediaItem;
      return audioSource;
    } else {
      final audioSource = AudioSource.file(mediaItem.id);
      _mediaItemExpando[audioSource] = mediaItem;
      return audioSource;
    }
  }

  List<AudioSource> _itemsToSources(List<MediaItem> mediaItems) =>
      mediaItems.map(_itemToSource).toList();

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        // When the user resumes a media session, tell the system what the most
        // recently played item was.
        return _recentSubject.value;
      default:
        // Allow client to browse the media library.
        return _mediaLibrary.items[parentMediaId]!;
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _playlist.add(_itemToSource(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _playlist.addAll(_itemsToSources(mediaItems));
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    await _playlist.insert(index, _itemToSource(mediaItem));
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    await _playlist.clear();
    await _playlist.addAll(_itemsToSources(queue));
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    _mediaItemExpando[_player.sequence![index]] = mediaItem;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexOf(mediaItem);
    await _playlist.removeAt(index);
  }

  @override
  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _playlist.move(currentIndex, newIndex);
  }

  @override
  Future<void> skipToNext() async {
    disposeVideoController();
    _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    disposeVideoController();
    _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;
    disposeVideoController();
    // This jumps to the beginning of the queue item at [index].
    _player.seek(Duration.zero,
        index: _player.shuffleModeEnabled
            ? _player.shuffleIndices![index]
            : index);
  }

  @override
  Future<void> play() =>
      shouldPlayVideo() ? videoPlayerController!.play() : _player.play();

  @override
  Future<void> pause() =>
      shouldPlayVideo() ? videoPlayerController!.pause() : _player.pause();

  Future<int> currentPosition() async {
    int duration = 0;
    if (shouldPlayVideo()) {
      var videoPosition = await videoPlayerController?.position;
      if (videoPosition != null) {
        duration = videoPosition.inSeconds;
      }
    } else {
      duration = _player.position.inSeconds;
    }
    return duration;
  }

  @override
  Future<void> seek(Duration position) => shouldPlayVideo()
      ? videoPlayerController!.seekTo(position)
      : _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
        (state) => state.processingState == AudioProcessingState.idle);
  }

  bool _isPlaying() => videoPlayerController?.value.isPlaying ?? false;

  AudioProcessingState _processingState() {
    if (videoPlayerController == null)
      return AudioProcessingState.loading;
    else if (videoPlayerController!.value.isPlaying)
      return AudioProcessingState.ready;
    else if (videoPlayerController!.value.isBuffering)
      return AudioProcessingState.loading;
    else if (videoPlayerController!.value.isInitialized)
      return AudioProcessingState.idle;
    return AudioProcessingState.loading;
  }

  Duration _bufferedPosition() {
    if (videoPlayerController != null) {
      DurationRange? currentBufferedRange =
          (videoPlayerController!.value.buffered.isEmpty)
              ? null
              : (videoPlayerController?.value.buffered.firstWhere(
                  (durationRange) {
                    Duration position = videoPlayerController!.value.position;
                    bool isCurrentBufferedRange =
                        durationRange.start < position &&
                            durationRange.end > position;
                    return isCurrentBufferedRange;
                  },
                  orElse: () => DurationRange(
                      videoPlayerController!.value.position,
                      videoPlayerController!.value.position),
                ));
      if (currentBufferedRange == null) return Duration.zero;
      return currentBufferedRange.end;
    } else {
      return Duration.zero;
    }
  }

  /// Broadcasts the current state to all clients.
  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    List<MediaControl> controls = [];
    controls.add(
      MediaControl.skipToPrevious,
    );
    if (shouldPlayVideo()) {
      controls.add((_isPlaying()) ? MediaControl.pause : MediaControl.play);
    } else {
      controls.add(
        (playing) ? MediaControl.pause : MediaControl.play,
      );
    }
    controls.add(
      MediaControl.skipToNext,
    );
    final queueIndex = getQueueIndex(
        event.currentIndex, _player.shuffleModeEnabled, _player.shuffleIndices);
    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.pause,
        MediaAction.play,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: shouldPlayVideo()
          ? _processingState()
          : const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
      playing: shouldPlayVideo() ? _isPlaying() : playing,
      updatePosition: shouldPlayVideo()
          ? videoPlayerController?.value.position ?? Duration.zero
          : _player.position,
      bufferedPosition:
          shouldPlayVideo() ? _bufferedPosition() : _player.bufferedPosition,
      speed: shouldPlayVideo()
          ? videoPlayerController?.value.playbackSpeed ?? 1.0
          : _player.speed,
      queueIndex: queueIndex,
    ));
  }
}

// disposeStream

/// Provides access to a library of media items. In your app, this could come
/// from a database or web service.
class MediaLibrary {
  static const albumsRootId = 'albums';

  final items = <String, List<MediaItem>>{
    AudioService.browsableRootId: const [
      MediaItem(
        id: albumsRootId,
        title: "Albums",
        playable: false,
      ),
    ],
    albumsRootId: [],
  };
}
