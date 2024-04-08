import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:acela/src/models/hive_comments/new_hive_comment/newest_comment_model.dart';
import 'package:acela/src/models/login/login_bridge_response.dart';
import 'package:acela/src/models/user_stream/hive_user_stream.dart';
import 'package:acela/src/utils/communicator.dart';
import 'package:acela/src/utils/safe_convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HiveCommentDialog extends StatefulWidget {
  const HiveCommentDialog(
      {Key? key,
      required this.username,
      required this.author,
      required this.permlink,
      required this.hasKey,
      required this.hasAuthKey,
      required this.onClose,
      required this.onDone,
      this.depth})
      : super(key: key);
  final String username;
  final String author;
  final String permlink;
  final String hasKey;
  final String hasAuthKey;
  final int? depth;
  final Function(CommentItemModel? comment) onDone;
  final Function onClose;

  @override
  State<HiveCommentDialog> createState() => _HiveCommentDialogState();
}

class _HiveCommentDialogState extends State<HiveCommentDialog> {
  var isCommenting = false;
  late WebSocketChannel socket;
  var socketClosed = true;
  String? qrCode;
  var timer = 0;
  var timeoutValue = 0;
  Timer? ticker;
  var loadingQR = false;
  var textController = TextEditingController();
  var text = '';
  var shouldShowHiveAuth = false;

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
              "account": widget.username,
              "uuid": uuid,
              "key": widget.hasKey,
              "host": Communicator.hiveAuthServer
            };
            var jsonString = json.encode(jsonData);
            var utf8Data = utf8.encode(jsonString);
            var qr = base64.encode(utf8Data);
            qr = "has://sign_req/$qr";
            var uri = Uri.tryParse(qr);
            if (uri != null) {
              launchUrl(uri);
            }
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
            Future.delayed(const Duration(seconds: 6), () {
              if (mounted) {
                setState(() {
                  String currentUserName = widget.username;
                  CommentItemModel addedComment = CommentItemModel(
                    created: DateTime.now(),
                    author: currentUserName,
                    isLocallyAdded: true,
                    permlink:
                        "re-$currentUserName-${DateTime.now().toIso8601String()}",
                     parentAuthor: widget.author,
                    parentPermlink: widget.permlink,
                    body: textController.text,
                    depth: widget.depth == null ? 1 : widget.depth! + 1,
                    children: 0,
                  );
                  isCommenting = false;
                  widget.onDone(addedComment);
                  Navigator.of(context).pop();
                });
              }
            });
            break;
          case "sign_nack":
            setState(() {
              isCommenting = false;
              ticker?.cancel();
              qrCode = null;
            });
            showError("Comment was declined. Please try again.");
            break;
          case "sign_err":
            setState(() {
              ticker?.cancel();
              qrCode = null;
            });
            showError("Upvote action failed.");
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

  Widget _comment() {
    return Container(
      padding: EdgeInsets.all(10),
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Comment',
          hintText: 'Enter comment here.',
        ),
        keyboardType: TextInputType.multiline,
        minLines: 3,
        maxLines: 6,
        controller: textController,
        onChanged: (newTextValue) {
          setState(() {
            text = newTextValue;
          });
        },
      ),
    );
  }

  void saveButtonTapped(HiveUserData data) async {
    setState(() {
      isCommenting = true;
    });
    try {
      var user = data.username;
      if (user == null) return;
      const platform = MethodChannel('com.example.acela/auth');
      var description = base64.encode(utf8.encode(text));
      final String result = await platform.invokeMethod('commentOnContent', {
        'user': user,
        'author': widget.author,
        'permlink': widget.permlink,
        'comment': description,
        'postingKey': data.postingKey ?? '',
        'hasKey': data.keychainData?.hasId ?? '',
        'hasAuthKey': data.keychainData?.hasAuthKey ?? '',
      });
      var response = LoginBridgeResponse.fromJsonString(result);
      if (response.valid && response.error.isEmpty) {
        log("Successful upvote and bridge communication");
        if (response.error.isEmpty &&
            response.data != null &&
            response.data!.isNotEmpty &&
            data.keychainData?.hasAuthKey != null) {
          var socketData = {
            "cmd": "sign_req",
            "account": data.username!,
            "token": data.keychainData!.hasId,
            "data": response.data!,
          };
          log('Socket message is - ${json.encode(socketData)}');
          loadingQR = true;
          var jsonData = json.encode(socketData);
          socket.sink.add(jsonData);
        } else if (response.error.isEmpty) {
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) {
              setState(() {
                isCommenting = false;
                String currentUserName = widget.username;
                CommentItemModel addedComment = CommentItemModel(
                  created: DateTime.now(),
                  isLocallyAdded: true,
                  author: currentUserName,
                  permlink:
                      "re-$currentUserName-${DateTime.now().toIso8601String()}",
                  parentAuthor: widget.author,
                  parentPermlink: widget.permlink,
                  body: textController.text,
                  depth: widget.depth == null ? 1 : widget.depth! + 1,
                  children: 0,
                );
                widget.onDone(addedComment);
                showMessage('Comment published successfully');
                Navigator.of(context).pop();
              });
            }
          });
        }
      }
    } catch (e) {
      showError('Something went wrong.\n${e.toString()}');
    }
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
    var data = Provider.of<HiveUserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text("Add Comment"),
          subtitle: Text(
            "@${widget.author}/${widget.permlink}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: isCommenting || text.length == 0 || qrCode != null
            ? []
            : [
                IconButton(
                  onPressed: () {
                    saveButtonTapped(data);
                  },
                  icon: Icon(Icons.comment),
                ),
              ],
      ),
      body: SafeArea(
        child: isCommenting
            ? qrCode != null
                ? _showQRCodeAndKeychainButton(qrCode!)
                : const Center(child: CircularProgressIndicator())
            : qrCode != null
                ? _showQRCodeAndKeychainButton(qrCode!)
                : _comment(),
      ),
    );
  }
}
