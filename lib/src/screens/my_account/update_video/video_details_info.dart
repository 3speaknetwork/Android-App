import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/models/login/login_bridge_response.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/models/video_details_model/video_details.dart';
import 'package:acela/src/screens/my_account/my_account_screen.dart';
import 'package:acela/src/screens/my_account/update_video/add_bene_sheet.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/safe_convert.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tus_client/tus_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoDetailsInfo extends StatefulWidget {
  const VideoDetailsInfo({
    Key? key,
    required this.item,
    required this.title,
    required this.subtitle,
    required this.selectedCommunity,
    required this.justForEditing,
    required this.hasKey,
    required this.hasAuthKey,
    required this.appData,
    required this.isNsfwContent,
  }) : super(key: key);
  final String hasKey;
  final String hasAuthKey;
  final VideoDetails item;
  final String title;
  final String subtitle;
  final bool justForEditing;
  final String selectedCommunity;
  final HiveUserData appData;
  final bool isNsfwContent;

  @override
  State<VideoDetailsInfo> createState() => _VideoDetailsInfoState();
}

class _VideoDetailsInfoState extends State<VideoDetailsInfo> {
  var isCompleting = false;
  var isPickingImage = false;
  var uploadStarted = false;
  var uploadComplete = false;
  var thumbIpfs = '';
  var thumbUrl = '';
  var tags = 'threespeak,mobile';
  var progress = 0.0;
  var processText = '';
  TextEditingController tagsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? hiveKeychainTransactionId;
  late WebSocketChannel socket;
  var socketClosed = true;
  String? qrCode;
  var timer = 0;
  var timeoutValue = 0;
  Timer? ticker;
  var loadingQR = false;
  var shouldShowHiveAuth = false;
  var powerUp100 = false;
  late String beneficiaries;

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
    beneficiaries =
    // '[{"account":"${widget.appData.username!}","weight":10000,"src":"publisher"}]';
    tagsController.text =
        widget.item.tags.isEmpty ? "threespeak,mobile" : widget.item.tags;
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
                    showMessage('Congratulations. Your video is published.');
                    showMyDialog();
                  });
                } catch (e) {
                  setState(() {
                    qrCode = null;
                    isCompleting = false;
                    processText = '';
                    showMessage(
                        'Video is posted on Hive but needs to be marked as published. Please hit Save button again after few seconds.');
                  });
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
        var v = await Communicator().updateInfo(
            user: user,
            videoId: widget.item.id,
            title: widget.title,
            description: widget.subtitle,
            isNsfwContent: widget.isNsfwContent,
            tags: tags,
            thumbnail: thumbIpfs.isEmpty ? null : thumbIpfs,
            communityID: widget.selectedCommunity);
        if (widget.justForEditing) {
          setState(() {
            showMessage('Video details are saved.');
            var screen = MyAccountScreen(data: user);
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            var route = MaterialPageRoute(builder: (c) => screen);
            Navigator.of(context).push(route);
          });
          return;
        }
        await Future.delayed(const Duration(seconds: 1), () {});
        const platform = MethodChannel('com.example.acela/auth');
        var title = base64.encode(utf8.encode(widget.title));
        var description = widget.subtitle;
        // if (!(description.contains(Communicator.suffixText))) {
        //   description = "$description\n${Communicator.suffixText}";
        // }
        description = base64.encode(utf8.encode(description));
        var ipfsHash = "";
        if (widget.item.video_v2.isNotEmpty) {
          ipfsHash = widget.item.video_v2
              .replaceAll("https://ipfs-3speak.b-cdn.net/ipfs/", "")
              .replaceAll("ipfs://", "")
              .replaceAll("/manifest.m3u8", "");
        }
        final String response = await platform.invokeMethod('newPostVideo', {
          'thumbnail': v.thumbnailValue,
          'video_v2': v.videoValue,
          'description': description,
          'title': title,
          'tags': v.tags,
          'username': user.username,
          'permlink': v.permlink,
          'duration': v.duration,
          'size': v.size,
          'originalFilename': v.originalFilename,
          'firstUpload': v.firstUpload,
          'bene': v.benes[0],
          'beneW': v.benes[1],
          'postingKey': user.postingKey ?? '',
          'community': widget.selectedCommunity,
          'ipfsHash': ipfsHash,
          'hasKey': user.keychainData?.hasId ?? '',
          'hasAuthKey': user.keychainData?.hasAuthKey ?? '',
        });
        log('Response from platform $response');
        var bridgeResponse = LoginBridgeResponse.fromJsonString(response);
        if (bridgeResponse.error == "success") {
          showMessage(
              'Please wait. Video is posted on Hive but needs to be marked as published.');
          Future.delayed(const Duration(seconds: 6), () async {
            if (mounted) {
              try {
                await Communicator().updatePublishState(user, v.id);
                setState(() {
                  isCompleting = false;
                  processText = '';
                  showMessage('Congratulations. Your video is published.');
                  showMyDialog();
                });
              } catch (e) {
                setState(() {
                  isCompleting = false;
                  processText = '';
                  showMessage(
                      'Video is posted on Hive but needs to be marked as published. Please hit Save button again after few seconds.');
                });
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
      showError(e.toString());
      setState(() {
        isCompleting = false;
        processText = '';
      });
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

  // void showDialogForHASTransaction(String uuid) {
  //   Widget okButton = TextButton(
  //     child: Text("Okay"),
  //     onPressed: () {
  //       Navigator.of(context).pop();
  //     },
  //   );
  //   AlertDialog alert = AlertDialog(
  //     title: Text("Launch HiveAuth / HiveKeychain"),
  //     content: Text("Transaction - $uuid is waiting for approval. Please launch \"Keychain for Hive\" and approve to publish on Hive."),
  //     actions: [
  //       okButton,
  //     ],
  //   );
  //   showDialog(context: context, builder: (c) => alert);
  // }

  void showMyDialog() {
    Widget okButton = TextButton(
      child: Text("Okay"),
      onPressed: () {
        Navigator.of(context).pop();
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

  Widget _thumbnailPicker(HiveUserData user) {
    return Center(
      child: Container(
        width: 320,
        height: 160,
        margin: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 3,
                blurRadius: 3,
              )
            ]),
        child: InkWell(
          child: Center(
            child: isPickingImage
                ? const CircularProgressIndicator()
                : progress > 0.0 && progress < 100.0
                    ? CircularProgressIndicator(value: progress)
                    : thumbUrl.isNotEmpty
                        ? Image.network(
                            thumbUrl,
                            width: 320,
                            height: 160,
                          )
                        : widget.item.getThumbnail().isNotEmpty
                            ? Image.network(
                                widget.item.getThumbnail(),
                                width: 320,
                                height: 160,
                              )
                            : const Text(
                                'Tap here to add thumbnail for your video\n\nThumbnail is MANDATORY to set.',
                                textAlign: TextAlign.center),
          ),
          onTap: () async {
            try {
              setState(() {
                isPickingImage = true;
              });
              final XFile? file =
                  await _picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                setState(() {
                  isPickingImage = false;
                });
                initiateUpload(user, file);
              } else {
                throw 'User cancelled image picker';
              }
            } catch (e) {
              showError(e.toString());
              setState(() {
                isPickingImage = false;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _tagField() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: TextField(
        controller: tagsController,
        decoration: const InputDecoration(
          hintText: 'Comma separated tags',
          labelText: 'Tags',
        ),
        onChanged: (text) {
          setState(() {
            tags = text;
          });
        },
        maxLines: 1,
        minLines: 1,
        maxLength: 150,
      ),
    );
  }

  Widget _rewardType() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
      child: Row(
        children: [
          Text('Type:'),
          Spacer(),
          SizedBox(
            width: 250.0,
            child: CupertinoSegmentedControl(
              children: {
                0: Center(
                  child: Text('50% Power', textAlign: TextAlign.center),
                ),
                1: Center(
                  child: Text('100% Power', textAlign: TextAlign.center),
                )
              },
              selectedColor: Theme.of(context).primaryColor,
              borderColor: Theme.of(context).primaryColor,
              groupValue: powerUp100 ? 1 : 0,
              onValueChanged: (value) {
                setState(() {
                  if (value == 0) {
                    powerUp100 = false;
                  } else {
                    powerUp100 = true;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _beneficiaries() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          beneficiariesBottomSheet();
        },
        child: Row(
          children: [
            Text('Video Participants:'),
            Spacer(),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void showAlertForAddBene(List<BeneficiariesJson> benes) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return AddBeneSheet(benes: benes, onSave: (name, percent) {
          benes.add(BeneficiariesJson(account: name, weight: percent, src: ''));
          var text = json.encode(benes);
          setState(() {
            beneficiaries = text;
          });
        });
      },
    );
  }


  void beneficiariesBottomSheet() {
    var benes = BeneficiariesJson.fromJsonString(beneficiaries);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 400,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Video Participants'),
                actions: [
                  IconButton(onPressed: (){
                    Navigator.of(context).pop();
                    showAlertForAddBene(benes);
                  }, icon: Icon(Icons.add))
                ],
              ),
              body: ListView.separated(
                itemBuilder: (c, i) {
                  var percent = '${(benes[i].weight.toDouble() / 100.0).toStringAsFixed(2)} %';
                  return ListTile(
                    leading: CustomCircleAvatar(
                      height: 40,
                      width: 40,
                      url: server.userOwnerThumb(benes[i].account),
                    ),
                    title: Text(benes[i].account),
                    subtitle: Text(benes[i].src),
                    trailing: Text(percent),
                  );
                },
                separatorBuilder: (c, i) => const Divider(),
                itemCount: benes.length,
              ),
            ),
          ),
        );
      },
    );
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
    var user = Provider.of<HiveUserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          leading: CustomCircleAvatar(
            height: 36,
            width: 36,
            url: 'https://images.hive.blog/u/${user.username ?? ''}/avatar',
          ),
          title: Text(user.username ?? ''),
          subtitle: Text('Provide more details to publish'),
        ),
      ),
      body: isCompleting
          ? (qrCode == null)
              ? Center(
                  child: LoadingScreen(
                    title: 'Please wait',
                    subtitle: processText,
                  ),
                )
              : _showQRCodeAndKeychainButton(qrCode!)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _tagField(),
                _thumbnailPicker(user),
                const Text('Tap to change video thumbnail'),
                if (!widget.justForEditing) _rewardType(),
                if (!widget.justForEditing) _beneficiaries(),
              ],
            ),
      floatingActionButton: isCompleting
          ? null
          : thumbIpfs.isNotEmpty || widget.item.getThumbnail().isNotEmpty
              ? FloatingActionButton.extended(
                  label: Text(widget.justForEditing ? 'Save Details' : 'Publish'),
                  onPressed: () {
                    if (user.username != null) {
                      completeVideo(user);
                    }
                  },
                  icon: Icon(widget.justForEditing ? Icons.save : Icons.post_add),
                )
              : null,
    );
  }
}
