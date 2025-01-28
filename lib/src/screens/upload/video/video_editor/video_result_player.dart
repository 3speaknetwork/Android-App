import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoResultPlayer extends StatefulWidget {
  const VideoResultPlayer({super.key, required this.video});

  final File video;

  @override
  State<VideoResultPlayer> createState() => _VideoResultPlayerState();
}

class _VideoResultPlayerState extends State<VideoResultPlayer> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isMuted = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _controller = VideoPlayerController.file(widget.video)
      ..initialize().then((_) {
        setState(() {});
        _controller?.play();
        _controller?.setLooping(true);
        if (_isMuted) {
          _controller?.setVolume(_isMuted ? 0 : 1);
        }
      });

    _startHideTimer();
  }

  @override
  void didUpdateWidget(covariant VideoResultPlayer oldWidget) {
    if (oldWidget != widget) {
      _controller?.dispose();
      _init();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      setState(() => _showControls = false);
    });
  }

  void _togglePlayPause() {
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _toggleMute() {
    _isMuted = !_isMuted;
    _controller?.setVolume(_isMuted ? 0 : 1);
    setState(() {});
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        height: 300,
        width: double.infinity,
        child: ClipRRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              widget(
                child: AspectRatio(
                  aspectRatio: _controller?.value.aspectRatio ?? 1,
                  child: _controller?.value.isInitialized == true
                      ? VideoPlayer(_controller!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              if (_showControls)
                AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 50,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              Positioned(
                bottom: 5,
                right: 5,
                child: IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
