import 'package:equatable/equatable.dart';

class VideoResolution extends Equatable {
  final int width;
  final int height;
  final String resolution;
  final bool isLandscape;
  final bool convertVideo;

  const VideoResolution({
    required this.width,
    required this.height,
    required this.isLandscape,
    this.convertVideo = true,
  }) : resolution = isLandscape ? '${width}p' : '${height}p';

  @override
  List<Object?> get props => [width, height, isLandscape, convertVideo];

  static String quality(VideoResolution resolution) =>
      '${resolution.isLandscape ? resolution.width : resolution.height}';
}
