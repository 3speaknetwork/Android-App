import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class VideoStorage {
  final List<String> defaultVideoEncodingQuality = ['480'];
  final GetStorage _storage = GetStorage();

  final String videoEncodeKey = "videoEncodeKey";

  List<String> readEncodingQualities() {
    String? result = _storage.read(videoEncodeKey);
    if (result != null) {
      return (json.decode(result) as List<dynamic>)
          .map((e) => e as String)
          .toList();
    }
    return defaultVideoEncodingQuality;
  }

  Future<void> writeVideoEncodingQuality(List<String> data) async {
    await _storage.write(videoEncodeKey, json.encode(data));
  }
}
