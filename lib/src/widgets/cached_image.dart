import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedImage extends StatelessWidget {
  const CachedImage(
      {Key? key,
      required this.imageUrl,
      this.imageHeight,
      this.imageWidth,
      this.loadingIndicatorSize,
      this.borderRadius,
      this.isCached = true,
      this.fit})
      : super(key: key);

  final String? imageUrl;
  final double? imageHeight;
  final double? imageWidth;
  final double? loadingIndicatorSize;
  final BoxFit? fit;
  final double? borderRadius;
  final bool isCached;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight == Colors.black
              ? Colors.grey.shade400
              : Colors.grey.shade900,
          borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 0))),
      child: isCached
          ? CachedNetworkImage(
              imageUrl: imageUrl ?? '',
              height: imageHeight,
              width: imageWidth,
              fit: fit ?? (imageHeight != null ? BoxFit.cover : null),
              errorWidget: (context, url, error) => _errorWidget(),
            )
          : Image.network(
              imageUrl ?? "",
              height: imageHeight,
              width: imageWidth,
              fit: fit ?? (imageHeight != null ? BoxFit.cover : null),
              errorBuilder: (context, error, stackTrace) => _errorWidget(),
            ),
    );
  }

  Image _errorWidget() {
    return Image.asset(
      'assets/ctt-logo.png',
      height: imageHeight,
      width: imageWidth,
    );
  }
}
