import 'dart:developer';

class Server {
  final String domain = "https://3speak.tv";
  String userOwnerThumb(String value) {
    return "https://images.hive.blog/u/$value/avatar";
  }

  String resizedImage(String value) {
    return "https://images.hive.blog/320x160/$value";
  }

  final String hiveDomain = "https://api.hive.blog";
}

Server server = Server();