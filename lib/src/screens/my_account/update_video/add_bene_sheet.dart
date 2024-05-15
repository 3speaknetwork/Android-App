import 'dart:developer';

import 'package:acela/src/models/my_account/video_ops.dart';
import 'package:acela/src/widgets/user_profile_image.dart';
import 'package:flutter/material.dart';

class AddBeneSheet extends StatefulWidget {
  const AddBeneSheet({
    Key? key,
    required this.benes,
    required this.onSave,
  }) : super(key: key);
  final List<BeneficiariesJson> benes;
  final Function(List<BeneficiariesJson> newBenes) onSave;

  @override
  State<AddBeneSheet> createState() => _AddBeneSheetState();
}

class _AddBeneSheetState extends State<AddBeneSheet> {
  var newBeneValue = 1;
  var name = '';
  var _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _beneNameField() {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                return UserProfileImage(userName: _controller.text);
              }),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Video Participant Hive Account Name',
                labelText: 'Account Name',
              ),
              onChanged: (text) {
                setState(() {
                  name = text;
                });
              },
              maxLines: 1,
              minLines: 1,
              maxLength: 150,
            ),
          ),
        ],
      ),
    );
  }

  void showError(String string) {
    var snackBar = SnackBar(content: Text('Error: $string'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showMessage(String string) {
    var snackBar = SnackBar(content: Text(string));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    int totalWeight = 0;
    widget.benes.forEach((element) {
      totalWeight += element.weight;
    });
    log(MediaQuery.of(context).viewInsets.bottom.toString());
    var max = (99 - totalWeight);
    return SafeArea(
        child: Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 400,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          AppBar(
            title: Text('Add Participant'),
            actions: [
              IconButton(
                onPressed: () {
                  if (name.isEmpty) return;
                  var names =
                      widget.benes.map((e) => e.account.toLowerCase()).toList();
                  var participant = name.toLowerCase().trim();
                  if (names.contains(participant)) {
                    showError('Video Participant already added');
                  } else {
                    var percentValue = newBeneValue;
                    var newList = widget.benes;
                    newList.add(
                      BeneficiariesJson(
                        account: participant,
                        weight: percentValue,
                        src: 'participant',
                      ),
                    );
                    // newList = newList.where((e) => e.src != 'author').toList();
                    // var sum = newList.map((e) => e.weight).toList().sum;
                    // var newWeight = 99 - sum;
                    // newList.add(
                    //   BeneficiariesJson(
                    //       account: author.account,
                    //       weight: newWeight,
                    //       src: 'author'),
                    // );
                    widget.onSave(newList);
                    Navigator.of(context).pop();
                  }
                },
                icon: Icon(Icons.add),
              )
            ],
          ),
          if (1 <= max &&
              newBeneValue.toDouble() >= 1 &&
              newBeneValue.toDouble() <= max)
            Expanded(
              child: ListView(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  _beneNameField(),
                  const SizedBox(
                    height: 15,
                  ),
                  Slider(
                    value: newBeneValue.toDouble(),
                    min: 1.0,
                    max: max.toDouble(),
                    activeColor: Theme.of(context).colorScheme.secondary,
                    onChanged: (val) {
                      setState(() {
                        newBeneValue = val.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(newBeneValue).toStringAsFixed(0)} %',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    ));
  }
}
