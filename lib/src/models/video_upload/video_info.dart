class VideoInfo {
  final String? originalFilename;
  final int? duration;
  final int? size;
  final int? width;
  final int? height;
  final String? tusId;

  VideoInfo({
    this.originalFilename,
    this.duration,
    this.size,
    this.width,
    this.height,
    this.tusId,
  });

  VideoInfo copyWith({
    String? originalFilename,
    int? duration,
    int? size,
    int? width,
    int? height,
    String? tusId,
  }) {
    return VideoInfo(
      originalFilename: originalFilename ?? this.originalFilename,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      tusId: tusId ?? this.tusId,
    );
  }
}
