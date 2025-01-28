import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/upload/video/video_editor/video_picker_screen.dart';
import 'package:acela/src/utils/graphql/gql_communicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VideoUploadSheet {
  static void show(HiveUserData data, BuildContext context) {
    void pushToVideoEditorScreen(){
       Navigator.of(context).push(MaterialPageRoute(builder: (c) => VideoPickerScreen()));
    }
    if (data.username != null && data.postingKey != null) {
     pushToVideoEditorScreen();
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
         pushToVideoEditorScreen();
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
