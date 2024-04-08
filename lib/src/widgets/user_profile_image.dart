import 'package:acela/src/bloc/server.dart';
import 'package:flutter/material.dart';

class UserProfileImage extends StatelessWidget {
  const UserProfileImage({Key? key, required this.userName, this.radius})
      : super(key: key);

  final String userName;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: radius ?? 40,
      width: radius ?? 40,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
          image: userName.isNotEmpty
              ? DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(
                    server.userOwnerThumb(userName),
                  ),
                )
              : null),
    );
  }
}
