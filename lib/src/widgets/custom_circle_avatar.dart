import 'package:flutter/material.dart';

class CustomCircleAvatar extends StatelessWidget {
  const CustomCircleAvatar(
      {Key? key, required this.height, required this.width, required this.url,this.color})
      : super(key: key);
  final double height;
  final double width;
  final String url;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: CircleAvatar(
        backgroundImage: NetworkImage(url),
        backgroundColor:color ?? Colors.transparent,
        radius: 100,
      ),
    );
  }
}
