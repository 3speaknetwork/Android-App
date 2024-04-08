import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/upload/new_video_upload_screen.dart';
import 'package:acela/src/screens/upload/podcast/audio_primary_info.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/media_information_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';
import 'package:tus_client/tus_client.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PodcastUploadScreen extends StatefulWidget {
  const PodcastUploadScreen({
    Key? key,
    required this.data,
  }) : super(key: key);
  final HiveUserData data;

  @override
  State<PodcastUploadScreen> createState() => _PodcastUploadScreenState();
}

class _PodcastUploadScreenState extends State<PodcastUploadScreen> {
  late Timer timer;
  var didShowFilePicker = false;
  var didPickFile = false;

  // var didCompress = false;
  var didUpload = false;

  var timeShowFilePicker = '0.5 seconds';
  var timePickFile = '';

  // var timeCompress = '';
  var timeUpload = '';

  var didStartPickFile = false;

  // var didStartCompress = false;
  var didStartUpload = false;
  var progress = 0.0;
  String fileName = "";
  String audioUrl = "";
  String tusFileName = "";
  int fileSize = 0;
  int duration = 0;

  late Subscription _subscription;
  HiveUserData? user;
  final LocalStorage storage = LocalStorage('uploaded_audio_data');
  final UploadedItemList list = UploadedItemList();

  @override
  void initState() {
    super.initState();
    var items = storage.getItem('audio_uploads');
    if (items != null) {
      setState(() {
        list.items = List<UploadedItem>.from(
          (items as List).map(
            (item) => UploadedItem(
              fileName: item['fileName'],
              filePath: item['filePath'],
            ),
          ),
        );
      });
    }
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      timer.cancel();
      videoPickerFunction();
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    // _subscription.unsubscribe();
  }

  void _addItem(String fileName, String filePath) {
    setState(() {
      final item = new UploadedItem(fileName: fileName, filePath: filePath);
      list.items.add(item);
      _saveToStorage();
    });
  }

  void _saveToStorage() {
    storage.setItem('uploads', list.toJSONEncodable());
  }

  void videoPickerFunction() async {
    try {
      if (user?.username == null) {
        throw 'User not logged in';
      }
      // Step 1. Select Video
      var dateStartGettingVideo = DateTime.now();
      setState(() {
        didStartPickFile = true;
        didShowFilePicker = true;
      });

      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(type: Platform.isIOS ? FileType.any : FileType.audio);
      final XFile? file;
      file = pickerResult != null ? XFile(pickerResult.files.single.path ?? "") : null;
      if (file != null) {
        setState(() {
          didPickFile = true;
        });

        var originalFileName = file.name;
        setState(() {
          fileName = originalFileName;
        });
        log(originalFileName);
        log("path - ${file.path}");
        var alreadyUploaded = list.items.contains((e) {
          return e.fileName == originalFileName || e.filePath == file!.path;
        });
        var extension = file.path.split(".").last;
        if (extension != "mp3") {
          throw 'Podcast should be in mp3 format.';
        }
        if (alreadyUploaded) {
          throw 'This podcast is already uploaded by you';
        }
        var size = await file.length();
        var dateEndGettingVideo = DateTime.now();
        var diff = dateEndGettingVideo.difference(dateStartGettingVideo);
        setState(() {
          timePickFile = '${diff.inSeconds} seconds';
          didPickFile = true;
        });

        // Step 3. Video upload
        var dateStartUploadVideo = DateTime.now();
        setState(() {
          didStartUpload = true;
        });
        var fileSize = size;
        var sizeInMb = fileSize / 1000 / 1000;
        log("Compressed audio file size in mb is - $sizeInMb");
        if (sizeInMb > 1024) {
          throw 'Podcast Episode is too big to be uploaded from mobile (exceeding 500 mb)';
        }
        var path = file.path;
        MediaInformationSession session = await FFprobeKit.getMediaInformation(path);
        var info = session.getMediaInformation();
        var duration = (double.tryParse(info?.getDuration() ?? "0.0") ?? 0.0).toInt();
        log('Podcast Episode duration is $duration');
        setState(() {
          this.duration = duration;
          this.fileSize = fileSize;
        });
        var name = await initiateUpload(path);
        log(name);
        var dateEndUploadVideo = DateTime.now();
        diff = dateEndUploadVideo.difference(dateStartUploadVideo);
        setState(() {
          timeUpload = '${diff.inSeconds} seconds';
          didUpload = true;
          tusFileName = name;
        });
        _addItem(originalFileName, file.path);
        showMessage('Podcast Episode Audio is uploaded. Hit Next to finish next action items to publish podcast episode.');
        showMyDialog();
        // Step 6. Move Video to Queue
      } else {
        throw 'User cancelled the audio picker';
      }
    } catch (e) {
      setState(() {
        Navigator.of(context).pop();
      });
      rethrow;
    }
  }

  void showMyDialog() {
    Widget nowButton = TextButton(
        onPressed: () async {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          var screen = AudioPrimaryInfo(
            url: audioUrl,
            title: fileName,
            size: fileSize,
            duration: duration,
            episode: tusFileName,
          );
          var route = MaterialPageRoute(builder: (c) => screen);
          Navigator.of(context).push(route);
        },
        child: const Text('Next'));
    AlertDialog alert = AlertDialog(
      title: Text("🎉 Podcast Episode Audio Uploaded 🎉"),
      actions: [
        nowButton,
      ],
    );
    showDialog(context: context, builder: (c) => alert, barrierDismissible: false);
  }

  void showMessage(String string) {
    var snackBar = SnackBar(content: Text('Message: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> initiateUpload(String path) async {
    final xfile = XFile(path);
    final client = TusClient(
      Uri.parse(Communicator.fsServer),
      xfile,
      store: TusMemoryStore(),
    );
    var name = "";
    await client.upload(
      onComplete: () async {
        log("Complete!");
        // Prints the uploaded file URL
        log(client.uploadUrl.toString());
        var url = client.uploadUrl.toString();
        var ipfsName = url.replaceAll("${Communicator.fsServer}/", "");
        // var pathImageThumb = await getThumbnail(xfile.path);
        setState(() {
          didUpload = true;
          audioUrl = url;
        });
        name = ipfsName;
      },
      onProgress: (progress) {
        log("Progress: $progress");
        setState(() {
          this.progress = progress / 100.0;
        });
      },
    );
    return name;
  }

  Future<String> getThumbnail(String path) async {
    try {
      Directory tempDir = Directory.systemTemp;
      var imagePath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 320,
        quality: 100,
      );
      if (imagePath == null) {
        throw 'Could not generate video thumbnail';
      }
      return imagePath;
    } catch (e) {
      throw 'Error generating video thumbnail ${e.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<HiveUserData>(context);
    if (user.username != null && this.user == null) {
      this.user = user;
    }
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          leading: CustomCircleAvatar(
            height: 36,
            width: 36,
            url: 'https://images.hive.blog/u/${user.username ?? ''}/avatar',
          ),
          title: Text(user.username ?? ''),
          subtitle: Text('Audio Upload Process'),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Uploading Audio (${didUpload ? 100.0 : (progress * 100).toStringAsFixed(2)}%)'),
            trailing: !didStartUpload
                ? const Icon(Icons.pending)
                : !didUpload
                    ? SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(value: progress),
                      )
                    : const Icon(Icons.check, color: Colors.lightGreen),
            subtitle: didUpload ? Text(timeUpload) : null,
          ),
        ],
      ),
    );
  }
}
