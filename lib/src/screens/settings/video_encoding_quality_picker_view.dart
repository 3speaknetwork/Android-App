import 'package:acela/src/utils/storages/video_storage.dart';
import 'package:flutter/material.dart';

class VideoEncodingQualityPickerView extends StatefulWidget {
  @override
  _VideoEncodingQualityPickerViewState createState() =>
      _VideoEncodingQualityPickerViewState();
}

class _VideoEncodingQualityPickerViewState
    extends State<VideoEncodingQualityPickerView> {
  final VideoStorage _storage = VideoStorage();
  List<String> _qualities = [];

  @override
  void initState() {
    _qualities = _storage.readEncodingQualities();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Encoding Resolutions')),
      body: ListView(
        children: [
          CheckboxListTile(
            title: Text('480p'),
            value: _qualities.contains('480'),
            onChanged: (value) {},
          ),
          CheckboxListTile(
            title: Text('720p'),
            value: _qualities.contains('720'),
            onChanged: (value) {
              _onChanged('720');
            },
          ),
          CheckboxListTile(
            title: Text('1080p'),
            value: _qualities.contains('1080'),
            onChanged: (value) {
              _onChanged('1080');
            },
          ),
        ],
      ),
    );
  }

  void _onChanged(String quality) {
    if (_qualities.contains(quality)) {
      _qualities.remove(quality);
    } else {
      _qualities.add(quality);
    }
    if (mounted) {
      setState(() {
        _qualities.toSet().toList();
        _storage.writeVideoEncodingQuality(_qualities);
        print(_qualities);
      });
    }
  }
}
