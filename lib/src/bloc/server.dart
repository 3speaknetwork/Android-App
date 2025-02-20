import 'dart:async';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';

class Server {
  final String domain = "https://3speak.tv";

  String userOwnerThumb(String value) {
    return "https://images.hive.blog/u/$value/avatar";
  }

  String userChannelCover(String value) {
    return "https://img.3speakcontent.co/user/$value/cover.png";
  }

  String communityIcon(String value) {
    return "https://images.hive.blog/u/$value/avatar?size=icon";
  }

  String resizedImage(String value) {
    return "https://images.hive.blog/640x0/$value";
  }

  final _controller = StreamController<bool>();
  final _hiveUserDataController = StreamController<HiveUserData>();

  Stream<bool> get theme {
    return _controller.stream;
  }

  Stream<HiveUserData> get hiveUserData {
    return _hiveUserDataController.stream;
  }

  void changeTheme(bool value) async {
    _controller.sink.add(!value);
  }

  void updateHiveUserData(HiveUserData data) {
    _hiveUserDataController.sink.add(data);
  }
}

Server server = Server();
