import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/global_provider/ipfs_node_provider.dart';
import 'package:acela/src/models/login/login_bridge_response.dart';
import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/screens/my_account/update_video/add_bene_sheet.dart';
import 'package:acela/src/screens/settings/settings_screen.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/safe_convert.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:acela/src/widgets/loading_screen.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tus_client/tus_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AudioDetailsInfoScreen extends StatefulWidget {
  const AudioDetailsInfoScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.selectedCommunity,
    required this.hasKey,
    required this.hasAuthKey,
    required this.appData,
    required this.isNsfwContent,
    required this.owner,
    required this.size,
    required this.duration,
    required this.oFileName,
    required this.episode,
  }) : super(key: key);

  final String owner;
  final String title;
  final String description;
  final String hasKey;
  final String hasAuthKey;
  final String selectedCommunity;
  final HiveUserData appData;
  final bool isNsfwContent;
  final int size;
  final int duration;
  final String oFileName;
  final String episode;

  @override
  State<AudioDetailsInfoScreen> createState() => _AudioDetailsInfoScreenState();
}

class _AudioDetailsInfoScreenState extends State<AudioDetailsInfoScreen> {
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
  late List<BeneficiariesJson> beneficiaries;
  var podcastEpisodeId = "";

  var languages = [
    VideoLanguage(code: "en", name: "English"),
    VideoLanguage(code: "de", name: "Deutsch"),
    VideoLanguage(code: "pt", name: "Portuguese"),
    VideoLanguage(code: "fr", name: "Français"),
    VideoLanguage(code: "es", name: "Español"),
    VideoLanguage(code: "nl", name: "Nederlands"),
    VideoLanguage(code: "ko", name: "한국어"),
    VideoLanguage(code: "ru", name: "русский"),
    VideoLanguage(code: "hu", name: "Magyar"),
    VideoLanguage(code: "ro", name: "Română"),
    VideoLanguage(code: "cs", name: "čeština"),
    VideoLanguage(code: "pl", name: "Polskie"),
    VideoLanguage(code: "in", name: "bahasa Indonesia"),
    VideoLanguage(code: "bn", name: "বাংলা"),
    VideoLanguage(code: "it", name: "Italian"),
    VideoLanguage(code: "he", name: "עִברִית"),
  ];
  var selectedLanguage = VideoLanguage(code: "en", name: "English");

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
                const Text('Tap to change Podcast Episode thumbnail'),
                _rewardType(),
                _beneficiaries(),
                _changeLanguage(),
              ],
            ),
      floatingActionButton: isCompleting
          ? null
          : FloatingActionButton.extended(
              label: Text('Publish'),
              onPressed: () {
                if (user.username != null) {
                  completePodcastUpload(user);
                }
              },
              icon: Icon(Icons.post_add),
            ),
    );
  }

  void completePodcastUpload(HiveUserData user) async {
    if (thumbIpfs.isEmpty) {
      showError('Please set Thumbnail');
    } else {
      const platform = MethodChannel('com.example.acela/auth');
      setState(() {
        isCompleting = true;
        processText = 'Updating Podcast info';
      });
      try {
        final String ipfsUrl = IpfsNodeProvider().nodeUrl;
        var podcastResponse = await Communicator().uploadPodcast(
          user: user,
          size: widget.size,
          episode: widget.episode,
          oFilename: widget.oFileName,
          title: widget.title,
          description: widget.description,
          isNsfwContent: widget.isNsfwContent,
          tags: tags,
          thumbnail: thumbIpfs,
          communityID: widget.selectedCommunity,
          declineRewards: false,
          duration: widget.duration,
        );
        podcastEpisodeId = podcastResponse.id;
        await Future.delayed(const Duration(seconds: 1), () {});
        var title = base64.encode(utf8.encode(podcastResponse.title));
        var description = podcastResponse.description;
        description = base64.encode(utf8.encode(description));
        var ipfsHash = "";
        if (podcastResponse.enclosureUrl.isNotEmpty) {
          ipfsHash = podcastResponse.enclosureUrl
              .replaceAll(ipfsUrl, "")
              .replaceAll("ipfs://", "");
        }
        var thumbnail =
            podcastResponse.thumbnail.replaceAll("ipfs://", ipfsUrl);
        var enclosureUrl =
            podcastResponse.enclosureUrl.replaceAll("ipfs://", ipfsUrl);
        final String response = await platform.invokeMethod('newPostPodcast', {
          'thumbnail': thumbnail,
          'enclosureUrl': enclosureUrl,
          'description': description,
          'title': title,
          'tags': tags,
          'username': user.username,
          'permlink': podcastResponse.permlink,
          'duration': widget.duration.toDouble(),
          'size': widget.size,
          'originalFilename': widget.oFileName,
          'firstUpload': podcastResponse.firstUpload,
          'bene': '',
          'beneW': '',
          'postingKey': user.postingKey ?? '',
          'community': widget.selectedCommunity,
          'ipfsHash': ipfsHash,
          'hasKey': user.keychainData?.hasId ?? '',
          'hasAuthKey': user.keychainData?.hasAuthKey ?? '',
          'newBene': base64.encode(
              utf8.encode(BeneficiariesJson.toJsonString(beneficiaries))),
          'language': selectedLanguage.code,
          'powerUp': powerUp100,
        });
        log('Response from platform $response');
        var bridgeResponse = LoginBridgeResponse.fromJsonString(response);
        if (bridgeResponse.error == "" &&
            bridgeResponse.valid &&
            (bridgeResponse.data ?? "").isEmpty) {
          showMessage(
              'Please wait. Podcast is posted on Hive but needs to be marked as published.');
          Future.delayed(const Duration(seconds: 6), () async {
            if (mounted) {
              try {
                await Communicator().updatePublishStateForPodcastEpisode(
                    user, podcastResponse.id);
                setState(() {
                  isCompleting = false;
                  processText = '';
                  showMessage(
                      'Congratulations. Your Podcast Episode is published.');
                  showMyDialog();
                });
              } catch (e) {
                setState(
                  () {
                    isCompleting = false;
                    processText = '';
                    showMessage(
                        'Podcast is posted on Hive but needs to be marked as published. Please hit Save button again after few seconds.');
                  },
                );
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
      } catch (e) {
        showError(e.toString());
        setState(() {
          isCompleting = false;
          processText = '';
        });
      }
    }
  }

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
    beneficiaries = [
      BeneficiariesJson(account: 'sagarkothari88', src: 'mobile', weight: 1),
      BeneficiariesJson(
          account: 'spk.beneficiary', src: 'threespeak', weight: 10),
      BeneficiariesJson(
          account: widget.appData.username!, src: 'author', weight: 89),
    ];
    tagsController.text = "threespeak,mobile";
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
              "account": widget.owner,
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
                'Please wait. Podcast is posted on Hive but needs to be marked as published.');
            Future.delayed(const Duration(seconds: 6), () async {
              if (mounted) {
                try {
                  await Communicator().updatePublishStateForPodcastEpisode(
                      widget.appData, podcastEpisodeId);
                  setState(() {
                    isCompleting = false;
                    processText = '';
                    showMessage(
                        'Congratulations. Your Podcast Episode is published.');
                    showMyDialog();
                  });
                } catch (e) {
                  setState(
                    () {
                      isCompleting = false;
                      processText = '';
                      showMessage(
                          'Podcast is posted on Hive but needs to be marked as published. Please hit Save button again after few seconds.');
                    },
                  );
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

  Future<void> initiateUpload(
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
          "Your Podcast is published on Hive & podcast is marked as published."),
      actions: [
        okButton,
      ],
    );
    showDialog(context: context, builder: (c) => alert);
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

  Widget _rewardType() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 20),
      child: Row(
        children: [
          Text(powerUp100 ? '100% power' : '50% power'),
          const Spacer(),
          Switch(
            value: powerUp100,
            onChanged: (newVal) {
              setState(() {
                powerUp100 = newVal;
              });
            },
          )
        ],
      ),
    );
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
                        : const Text(
                            'Tap here to add thumbnail for your podcast\n\nThumbnail is MANDATORY to set.',
                            textAlign: TextAlign.center),
          ),
          onTap: () async {
            try {
              setState(() {
                isPickingImage = true;
                if (thumbUrl.isNotEmpty) {
                  thumbUrl = "";
                }
                if (thumbIpfs.isNotEmpty) {
                  thumbIpfs = "";
                }
              });
              XFile? file =
                  await _picker.pickImage(source: ImageSource.gallery);
              CropImageResult? result;
              if (file != null) {
                if (defaultTargetPlatform == TargetPlatform.android) {
                  result = await showMaterialImageCropper(
                    context,
                    imageProvider: FileImage(File(file.path)),
                    enabledTransformations: Transformation.values,
                    allowedAspectRatios: [
                      CropAspectRatio(width: 3, height: 3), //squre shape
                    ],
                    postProcessFn: (result) async {
                      return result;
                    },
                  );
                } else {
                  result = await showCupertinoImageCropper(
                    context,
                    imageProvider: FileImage(File(file.path)),
                    enabledTransformations: Transformation.values,
                    allowedAspectRatios: [
                      CropAspectRatio(width: 3, height: 3), //squre shape
                    ],
                    postProcessFn: (result) async {
                      return result;
                    },
                  );
                }
                if (result != null) {
                  var croppedfile =
                      await saveCroppedImageToFile(result.uiImage, file.path);
                  file = XFile(croppedfile.path);

                  await initiateUpload(user, file);
                  setState(() {
                    isPickingImage = false;
                  });
                } else {
                  _onCancel();
                  throw 'User cancelled image cropper';
                }
              } else {
                _onCancel();
                file = null;
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

  void _onCancel() {
    setState(() {
      isPickingImage = false;
      if (thumbUrl.isNotEmpty) {
        thumbUrl = "";
      }
      if (thumbIpfs.isNotEmpty) {
        thumbIpfs = "";
      }
    });
  }

  Future<File> resizeImage(File file) async {
    img.Image image = img.decodeImage(file.readAsBytesSync())!;
    img.Image resizedImage = img.copyResize(image, width: 1080, height: 1080);
    List<int> compressedBytes = img.encodeJpg(
      resizedImage,
    );
    File compressedFile = File(file.path);
    compressedFile.writeAsBytesSync(compressedBytes);
    return compressedFile;
  }

  Future<File> saveCroppedImageToFile(
      ui.Image croppedImage, String savePath) async {
    ByteData? byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    String filePath = "$savePath";
    await File(filePath).writeAsBytes(pngBytes);
    if (croppedImage.width > 1080 || croppedImage.height > 1080) {
      return await resizeImage(File(filePath));
    } else {
      return File(filePath);
    }
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

  Widget _beneficiaries() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          beneficiariesBottomSheet();
        },
        child: Row(
          children: [
            Text('Podcast Participants:'),
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
        return AddBeneSheet(
          benes: benes,
          onSave: (newBenes) {
            setState(() {
              beneficiaries = newBenes;
            });
          },
        );
      },
    );
  }

  void beneficiariesBottomSheet() {
    var filteredBenes = beneficiaries
        .where((element) =>
            element.src != 'ENCODER_PAY' &&
            element.src != 'mobile' &&
            element.src != 'threespeak')
        .toList();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 400,
            child: Scaffold(
              appBar: AppBar(
                title: Text('Podcast Participants'),
                actions: [
                  if (beneficiaries.length < 8)
                    IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showAlertForAddBene(beneficiaries);
                        },
                        icon: Icon(Icons.add))
                ],
              ),
              body: ListView.separated(
                itemBuilder: (c, i) {
                  return ListTile(
                    leading: CustomCircleAvatar(
                      height: 40,
                      width: 40,
                      url: server.userOwnerThumb(filteredBenes[i].account),
                    ),
                    title: Text(filteredBenes[i].account),
                    subtitle: Text(
                        '${filteredBenes[i].src} ( ${filteredBenes[i].weight} % )'),
                    trailing: (filteredBenes[i].src == 'participant')
                        ? IconButton(
                            onPressed: () {
                              var currentBenes = beneficiaries;
                              var author = currentBenes
                                  .where((e) => e.account == widget.owner)
                                  .firstOrNull;
                              if (author == null) return;
                              var otherBenes = currentBenes
                                  .where((e) =>
                                      e.src != 'author' &&
                                      e.account != filteredBenes[i].account)
                                  .toList();
                              author.weight =
                                  author.weight + filteredBenes[i].weight;
                              otherBenes.add(author);
                              setState(() {
                                beneficiaries = otherBenes;
                              });
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          )
                        : null,
                  );
                },
                separatorBuilder: (c, i) => const Divider(),
                itemCount: filteredBenes.length,
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

  BottomSheetAction getLangAction(VideoLanguage language) {
    return BottomSheetAction(
      title: Text(language.name),
      onPressed: (context) async {
        setState(() {
          selectedLanguage = language;
          Navigator.of(context).pop();
        });
      },
    );
  }

  void tappedLanguage() {
    showAdaptiveActionSheet(
      context: context,
      title: const Text('Set Default Language Filter'),
      androidBorderRadius: 30,
      actions: languages.map((e) => getLangAction(e)).toList(),
      cancelAction: CancelAction(title: const Text('Cancel')),
    );
  }

  Widget _changeLanguage() {
    var display = selectedLanguage.name;
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text("Set Language Filter"),
      trailing: Text(display),
      onTap: () {
        tappedLanguage();
      },
    );
  }
}
