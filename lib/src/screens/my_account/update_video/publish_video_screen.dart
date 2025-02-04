import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/global_provider/ipfs_node_provider.dart';
import 'package:acela/src/models/login/login_bridge_response.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/safe_convert.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tus_client/tus_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PublishVideoScreen extends StatefulWidget {
  const PublishVideoScreen({
    Key? key,
    required this.item,
    required this.hasKey,
    required this.hasAuthKey,
    required this.appData,
  }) : super(key: key);
  final String hasKey;
  final String hasAuthKey;
  final VideoDetails item;

  final HiveUserData appData;

  @override
  State<PublishVideoScreen> createState() => _PublishVideoScreenState();
}

class _PublishVideoScreenState extends State<PublishVideoScreen> {
  var isCompleting = false;
  var uploadStarted = false;
  var uploadComplete = false;
  var thumbIpfs = '';
  var thumbUrl = '';
  var progress = 0.0;
  var processText = '';
  String? hiveKeychainTransactionId;
  late WebSocketChannel socket;
  var socketClosed = true;
  String? qrCode;
  var timer = 0;
  var timeoutValue = 0;
  Timer? ticker;
  var loadingQR = false;
  var shouldShowHiveAuth = false;
  late List<BeneficiariesJson> beneficiaries;



  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showMessage(String string) {
    var snackBar = SnackBar(content: Text('Message: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    beneficiaries = widget.item.benes;
    setBeneficiares();
    socket = WebSocketChannel.connect(
      Uri.parse(Communicator.hiveAuthServer),
    );
    socket.stream.listen((message) {
      var map = json.decode(message) as Map<String, dynamic>;
      var cmd = asString(map, 'cmd');
      if (cmd.isNotEmpty) {
        switch (cmd) {
          case "connected":
            setState(() {
              timeoutValue = asInt(map, 'timeout');
            });
            break;
          case "auth_wait":
            log('You are not logged in.');
            break;
          case "auth_ack":
            log('You are not logged in.');
            break;
          case "auth_nack":
            log('You are not logged in.');
            break;
          case "sign_wait":
            var uuid = asString(map, 'uuid');
            var jsonData = {
              "account": widget.item.owner,
              "uuid": uuid,
              "key": widget.hasKey,
              "host": Communicator.hiveAuthServer
            };
            var jsonString = json.encode(jsonData);
            var utf8Data = utf8.encode(jsonString);
            var qr = base64.encode(utf8Data);
            qr = "has://sign_req/$qr";
            setState(() {
              loadingQR = false;
              qrCode = qr;
              var uri = Uri.tryParse(qr);
              if (uri != null) {
                launchUrl(uri);
              }
              timer = timeoutValue;
              ticker = Timer.periodic(Duration(seconds: 1), (tickrr) {
                if (timer == 0) {
                  setState(() {
                    tickrr.cancel();
                    qrCode = null;
                  });
                } else {
                  setState(() {
                    timer--;
                  });
                }
              });
            });
            break;
          case "sign_ack":
            setState(() {
              qrCode = null;
            });
            showMessage(
                'Please wait. Video is posted on Hive but needs to be marked as published.');
            Future.delayed(const Duration(seconds: 6), () async {
              if (mounted) {
                try {
                  await Communicator()
                      .updatePublishState(widget.appData, widget.item.id);
                  setState(() {
                    isCompleting = false;
                    processText = '';
                    qrCode = null;
                    // showMessage('Congratulations. Your video is published.');
                    showMyDialog();
                  });
                } catch (e) {
                  setState(() {
                    qrCode = null;
                    isCompleting = false;
                    processText = '';
                    // showMessage(
                    //     'Video is posted on Hive but needs to be marked as published. Please try again.');
                  });
                  Navigator.pop(context);
                }
              }
            });
            break;
          case "sign_nack":
            setState(() {
              isCompleting = false;
              processText = '';
              qrCode = null;
            });
            var uuid = asString(map, 'uuid');
            showError(
                "Transaction - $uuid was declined. Please hit save button again to try again.");
            break;
          case "sign_err":
            setState(() {
              qrCode = null;
              isCompleting = false;
              processText = '';
            });
            var uuid = asString(map, 'uuid');
            showError("Transaction - $uuid failed.");
            break;
          default:
            log('Default case here');
        }
      }
    }, onError: (e) async {
      await Future.delayed(Duration(seconds: 2));
      socket = WebSocketChannel.connect(
        Uri.parse(Communicator.hiveAuthServer),
      );
    }, onDone: () async {
      await Future.delayed(Duration(seconds: 2));
      socket = WebSocketChannel.connect(
        Uri.parse(Communicator.hiveAuthServer),
      );
    }, cancelOnError: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completeVideo(widget.appData);
    });
  }

  void initiateUpload(
    HiveUserData data,
    XFile xFile,
  ) async {
    if (uploadStarted) return;
    setState(() {
      uploadStarted = true;
    });
    final client = TusClient(
      Uri.parse(Communicator.fsServer),
      xFile,
      store: TusMemoryStore(),
    );
    await client.upload(
      onComplete: () async {
        print("Complete!");
        print(client.uploadUrl.toString());
        var url = client.uploadUrl.toString();
        var ipfsName = url.replaceAll("${Communicator.fsServer}/", "");
        setState(() {
          thumbUrl = url;
          thumbIpfs = ipfsName;
          uploadComplete = true;
          uploadStarted = false;
        });
      },
      onProgress: (progress) {
        log("Progress: $progress");
        setState(() {
          this.progress = progress;
        });
      },
    );
  }

  void completeVideo(HiveUserData user) async {
    const platform = MethodChannel('com.example.acela/auth');
    setState(() {
      isCompleting = true;
      processText = 'Updating video info';
    });
    try {
      var doesPostNotExist = await Communicator()
          .doesPostNotExist(widget.item.owner, widget.item.permlink, user.rpc);
      if (doesPostNotExist != true) {
        await Communicator().updatePublishState(user, widget.item.id);
        setState(() {
          isCompleting = false;
          processText = '';
          showMessage('Your video was already published.');
          showMyDialog();
        });
      } else {
        var title = base64.encode(utf8.encode(widget.item.title));
        var description = widget.item.description;

        description = base64.encode(utf8.encode(description));
        var ipfsHash = "";
        if (widget.item.video_v2.isNotEmpty) {
          ipfsHash = widget.item.video_v2
              .replaceAll(IpfsNodeProvider().nodeUrl, "")
              .replaceAll("ipfs://", "")
              .replaceAll("/manifest.m3u8", "");
        }
        List<BeneficiariesJson> newBene = beneficiaries
            .toSet()
            .map((e) => e.copyWith(account: e.account.toLowerCase()))
            .toList()
          ..sort((a, b) =>
              a.account.toLowerCase().compareTo(b.account.toLowerCase()));
        final String response = await platform.invokeMethod('newPostVideo', {
          'thumbnail': widget.item.thumbnailValue,
          'video_v2': widget.item.videoValue,
          'description': description,
          'title': title,
          'tags': widget.item.tags,
          'username': user.username,
          'permlink': widget.item.permlink,
          'duration': widget.item.duration,
          'size': widget.item.size,
          'originalFilename': widget.item.originalFilename,
          'firstUpload': widget.item.firstUpload,
          'bene': '',
          'beneW': '',
          'postingKey': user.postingKey ?? '',
          'community': widget.item.community,
          'ipfsHash': ipfsHash,
          'hasKey': user.keychainData?.hasId ?? '',
          'hasAuthKey': user.keychainData?.hasAuthKey ?? '',
          'newBene': base64
              .encode(utf8.encode(BeneficiariesJson.toJsonString(newBene))),
          'language': widget.item.language,
          'powerUp': widget.item.isPowerUp,
        });
        log('Response from platform $response');
        var bridgeResponse = LoginBridgeResponse.fromJsonString(response);
        if ((bridgeResponse.error == "success" ||
                bridgeResponse.error.isEmpty) &&
            user.keychainData?.hasAuthKey == null) {
          // showMessage(
          //     'Please wait. Video is posted on Hive but needs to be marked as published.');
          Future.delayed(const Duration(seconds: 6), () async {
            if (mounted) {
              try {
                await Communicator().updatePublishState(user, widget.item.id);
                setState(() {
                  isCompleting = false;
                  processText = '';
                  // showMessage('Congratulations. Your video is published.');
                  showMyDialog();
                });
              } catch (e) {
                setState(() {
                  isCompleting = false;
                  processText = '';
                  // showMessage(
                  //     'Video is posted on Hive but needs to be marked as published. Please try again.');
                });
                Navigator.pop(context);
              }
            }
          });
        } else if (bridgeResponse.error == "" &&
            bridgeResponse.data != null &&
            user.keychainData?.hasAuthKey != null) {
          var socketData = {
            "cmd": "sign_req",
            "account": user.username!,
            "token": user.keychainData!.hasId,
            "data": bridgeResponse.data!,
          };
          var jsonData = json.encode(socketData);
          socket.sink.add(jsonData);
        } else {
          throw bridgeResponse.error;
        }
      }
    } catch (e) {
      setState(() {
        showError(e.toString());
        isCompleting = false;
        processText = '';
      });
      Navigator.pop(context);
    }
  }

  void showDialogForAfter10Seconds(String message) {
    Widget okButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text("🎉 Congratulations 🎉"),
      content: Text(message),
      actions: [
        okButton,
      ],
    );
    showDialog(context: context, builder: (c) => alert);
  }

  void showMyDialog() {
    Widget okButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
    AlertDialog alert = AlertDialog(
      title: Text("🎉 Congratulations 🎉"),
      content: Text(
          "Your Video is published on Hive & video is marked as published."),
      actions: [
        okButton,
      ],
    );
    showDialog(context: context, builder: (c) => alert);
  }

  void setBeneficiares({String? userName, bool resetBeneficiares = false}) {
    int mobileAppPayIndex = beneficiaries.indexWhere((element) =>
        (element.account == 'sagarkothari88' &&
            element.src == "MOBILE_APP_PAY"));
    int mobileAppPayAndEncoderPayIndex = beneficiaries.indexWhere((element) =>
        (element.account == 'sagarkothari88' &&
            (element.src == "MOBILE_APP_PAY_AND_ENCODER_PAY" ||
                element.src == "ENCODER_PAY_AND_MOBILE_APP_PAY")));

    if (mobileAppPayIndex != -1 && mobileAppPayAndEncoderPayIndex != -1) {
      beneficiaries.removeAt(mobileAppPayIndex);
    }
    for (int i = 0; i < beneficiaries.length; i++) {
      if (widget.appData.username! != 'sagarkothari88' &&
          beneficiaries[i].account == 'sagarkothari88') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      } else if (widget.appData.username! != 'spk.beneficiary' &&
          beneficiaries[i].account == 'spk.beneficiary') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      } else if (beneficiaries[i].src == 'ENCODER_PAY') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      } else if (beneficiaries[i].src == 'MOBILE_APP_PAY_AND_ENCODER_PAY') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      } else if (beneficiaries[i].src == 'ENCODER_PAY_AND_MOBILE_APP_PAY') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      } else if (beneficiaries[i].src == 'MOBILE_APP_PAY') {
        beneficiaries[i] = beneficiaries[i].copyWith(isDefault: true);
      }
    }
    if (beneficiaries.indexWhere((element) =>
            (element.account == 'sagarkothari88' &&
                element.src == "MOBILE_APP_PAY") ||
            (element.account == 'sagarkothari88' &&
                (element.src == "MOBILE_APP_PAY_AND_ENCODER_PAY" ||
                    element.src == "ENCODER_PAY_AND_MOBILE_APP_PAY"))) ==
        -1) {
      beneficiaries.add(
        BeneficiariesJson(
            account: 'sagarkothari88',
            src: 'MOBILE_APP_PAY',
            weight: 1,
            isDefault: true),
      );
    }
    if (beneficiaries
            .indexWhere((element) => element.account == 'spk.beneficiary') ==
        -1) {
      beneficiaries.add(BeneficiariesJson(
          account: 'spk.beneficiary',
          src: 'threespeak',
          weight: 10,
          isDefault: true));
    }

    beneficiaries =
        beneficiaries.where((element) => element.src != 'author').toList();
  }

  Widget _showQRCodeAndKeychainButton(String qr) {
    Widget hkButton = ElevatedButton(
      onPressed: () {
        var uri = Uri.tryParse(qr);
        if (uri != null) {
          launchUrl(uri);
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
      child: Image.asset('assets/hive-keychain-image.png', width: 100),
    );
    Widget haButton = ElevatedButton(
      onPressed: () {
        setState(() {
          shouldShowHiveAuth = true;
        });
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
      child: Image.asset('assets/hive_auth_button.png', width: 120),
    );
    Widget qrCode = InkWell(
      child: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: QrImageView(
          data: qr,
          size: 150.0,
          gapless: true,
        ),
      ),
      onTap: () {
        var uri = Uri.tryParse(qr);
        if (uri != null) {
          launchUrl(uri);
        }
      },
    );
    var backButton = ElevatedButton.icon(
      onPressed: () {
        setState(() {
          shouldShowHiveAuth = false;
        });
      },
      icon: Icon(Icons.arrow_back),
      label: Text("Back"),
    );
    List<Widget> array = [];
    if (shouldShowHiveAuth) {
      array = [
        backButton,
        const SizedBox(width: 10),
        qrCode,
      ];
    } else {
      array = [
        haButton,
        const SizedBox(width: 10),
        hkButton,
      ];
    }
    return Center(
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: array,
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: timer.toDouble() / timeoutValue.toDouble(),
                  semanticsLabel: 'Timeout Timer for HiveAuth QR',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Publishing")),
      body: isCompleting
          ? (qrCode == null)
              ? Center(
                  child: LoadingScreen(
                    title: 'Please wait',
                    subtitle: processText,
                  ),
                )
              : _showQRCodeAndKeychainButton(qrCode!)
          : Center(
              child: Text("Video getting ready to get published"),
            ),
    );
  }
}
