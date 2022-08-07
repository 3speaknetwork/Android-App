import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:flutter/material.dart';

class VideoPrimaryInfo extends StatefulWidget {
  const VideoPrimaryInfo({
    Key? key,
    required this.item,
  }) : super(key: key);
  final VideoDetails item;

  @override
  State<VideoPrimaryInfo> createState() => _VideoPrimaryInfoState();
}

class _VideoPrimaryInfoState extends State<VideoPrimaryInfo> {
  var title = '';
  var description = '';

  Widget _body() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Video title goes here',
                labelText: 'Title',
              ),
              onChanged: (text) {
                setState(() {
                  title = text;
                });
              },
              maxLines: 1,
              minLines: 1,
              maxLength: 150,
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Video description',
                labelText: 'Description',
              ),
              onChanged: (text) {
                setState(() {
                  description = text;
                });
              },
              maxLines: 8,
              minLines: 5,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Info'),
      ),
      body: _body(),
      floatingActionButton: title.isNotEmpty && description.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // var screen = UploadExtraScreen(
                //   videoId: widget.videoId,
                //   title: title,
                //   description: description,
                //   ipfsName: ipfsName,
                //   thumbUrl: thumbUrl,
                // );
                // var route = MaterialPageRoute(builder: (c) => screen);
                // Navigator.of(context).push(route);
              },
              child: const Text('Next'),
            )
          : null,
    );
  }
}