import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/home_screen/home_screen_feed_item/widgets/video_encoder_switch.dart';
import 'package:acela/src/screens/upload/video/video_upload_screen.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VideoUploadSheet {
  static void show(HiveUserData data, BuildContext context) {
    if (data.username != null && data.postingKey != null) {
      _showBottomSheetForRecordingTypes(data, context);
    } else if (data.keychainData != null) {
      var expiry = data.keychainData!.hasExpiry;
      log('Expiry is $expiry');
      try {
        var longValue = int.tryParse(expiry) ?? 0;
        var expiryDate = DateTime.fromMillisecondsSinceEpoch(longValue);
        var nowDate = DateTime.now();
        log('Expiry Date is $expiryDate, now date is $nowDate');
        var compareResult = nowDate.compareTo(expiryDate);
        log('compare result - $compareResult');
        if (compareResult == -1) {
          _showBottomSheetForRecordingTypes(data, context);
        } else {
          _showError('Invalid Session. Please login again.', context);
          _logout(data);
        }
      } catch (e) {
        _showError('Invalid Session. Please login again.', context);
        _logout(data);
      }
    } else {
      _showError('Invalid Session. Please login again.', context);
      _logout(data);
    }
  }

  static void _showBottomSheetForRecordingTypes(
      HiveUserData data, BuildContext context) {
    _showBottomSheetForVideoOptions(false, data, context);
  }

  static void _showBottomSheetForVideoOptions(
      bool isReel, HiveUserData data, BuildContext context) {
    final ValueNotifier<bool> isDeviceEncode = ValueNotifier(false);
    showAdaptiveActionSheet(
      context: context,
      title: const Text('How do you want to upload?'),
      androidBorderRadius: 30,
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: const Text('Camera'),
          leading: const Icon(Icons.camera_alt),
          onPressed: (c) {
            var screen = VideoUploadScreen(
              isCamera: true,
              appData: data,
              isDeviceEncode: isDeviceEncode.value,
            );
            var route = MaterialPageRoute(builder: (c) => screen);
            Navigator.of(context).pop();
            Navigator.of(context).push(route);
          },
        ),
        BottomSheetAction(
            title: const Text('Photo Gallery'),
            leading: const Icon(Icons.photo_library),
            onPressed: (c) {
              var screen = VideoUploadScreen(
                isCamera: false,
                appData: data,
                isDeviceEncode: isDeviceEncode.value,
              );
              var route = MaterialPageRoute(builder: (c) => screen);
              Navigator.of(context).pop();
              Navigator.of(context).push(route);
            }),
        BottomSheetAction(
            title: const Text('Encode video on device'),
            leading: const Icon(Icons.emergency_outlined),
            trailing: VideoEncoderSwitch(
              valueNotifier: isDeviceEncode,
            ),
            onPressed: (c) {
              isDeviceEncode.value = !isDeviceEncode.value;
            }),
      ],
      cancelAction: CancelAction(
        title: const Text('Cancel'),
      ),
    );
  }

  static void _logout(HiveUserData data) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'username');
    await storage.delete(key: 'postingKey');
    await storage.delete(key: 'cookie');
    await storage.delete(key: 'hasId');
    await storage.delete(key: 'hasExpiry');
    await storage.delete(key: 'hasAuthKey');
    String resolution = await storage.read(key: 'resolution') ?? '480p';
    String rpc = await storage.read(key: 'rpc') ?? 'api.hive.blog';
    String union =
        await storage.read(key: 'union') ?? GQLCommunicator.defaultGQLServer;
    String? lang = await storage.read(key: 'lang');
    server.updateHiveUserData(
      HiveUserData(
        username: null,
        postingKey: null,
        keychainData: null,
        cookie: null,
        accessToken: null,
        postingAuthority: null,
        resolution: resolution,
        rpc: rpc,
        union: union,
        loaded: true,
        language: lang,
      ),
    );
  }

  static void _showError(String string, BuildContext context) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
