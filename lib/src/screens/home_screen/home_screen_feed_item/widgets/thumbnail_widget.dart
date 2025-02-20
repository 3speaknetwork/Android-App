import 'dart:ui';
import 'package:acela/src/bloc/server.dart';
import 'package:flutter/material.dart';

class ThumbnailWidget extends StatelessWidget {
  const ThumbnailWidget(
      {super.key,
      required this.image,
      required this.height,
      required this.width,
      this.verticalPadding = 8});

  final String image;
  final double? height;
  final double width;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorLight == Colors.black
          ? Colors.grey.shade400
          : Colors.grey.shade900,
      height: height,
      width: width,
      child: Stack(
        children: [
          if (image.isNotEmpty)
            Image.network(
              Server().resizedImage(
                image,
              ),
              height: height,
              width: width,
              fit: BoxFit.cover,
            ),
          if (image.isNotEmpty)
            Positioned.fill(
              top: -2,
              bottom: -2,
              left: -2,
              right: -2,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          Container(
              margin: EdgeInsets.symmetric(vertical: verticalPadding),
              height: height,
              width: width,
              child: _imageThumb(image, width, context)),
        ],
      ),
    );
  }

  Widget _imageThumb(String url, double width, BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: FadeInImage.assetNetwork(
        fit: BoxFit.contain,
        placeholder: "",
        image: Server().resizedImage(url),
        placeholderErrorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return const SizedBox.shrink();
        },
        imageErrorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return _errorIndicator(width, Theme.of(context));
        },
      ),
    );
  }

  Widget _errorIndicator(double width, ThemeData theme) {
    return Image.asset(
      'assets/ctt-logo.png',
      height: height,
      width: width,
    );
  }
}
