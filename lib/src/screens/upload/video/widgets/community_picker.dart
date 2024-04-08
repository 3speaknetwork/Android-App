import 'package:acela/src/bloc/server.dart';
import 'package:acela/src/screens/communities_screen/communities_screen.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:acela/src/widgets/custom_circle_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommunityPicker extends StatefulWidget {
  const CommunityPicker(
      {Key? key,
      required this.communityName,
      required this.communityId,
      required this.onChanged})
      : super(key: key);

  final String communityName;
  final String communityId;
  final Function(String, String) onChanged;

  @override
  State<CommunityPicker> createState() => _CommunityPickerState();
}

class _CommunityPickerState extends State<CommunityPicker> {
  String selectedCommunityName = "";
  String selectedCommunityId = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (c) => CommunitiesScreen(
                withoutScaffold: false,
                didSelectCommunity: (name, id) {
                  setState(() {
                    selectedCommunityName = name;
                    selectedCommunityId = id;
                  });
                  widget.onChanged(name, id);
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(
              left: kScreenHorizontalPaddingDigit,
              right: kScreenHorizontalPaddingDigit,
              top: 7),
          child: Row(
            children: [
              const Text('Select Community:'),
              Spacer(),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Visibility(
                    visible: selectedCommunityId.isNotEmpty &&
                        selectedCommunityName.isNotEmpty,
                    maintainState: true,
                    maintainSemantics: true,
                    maintainSize: true,
                    maintainAnimation: true,
                    child: Row(
                      children: [
                        Text(selectedCommunityName),
                        SizedBox(width: 10),
                        CustomCircleAvatar(
                          width: 44,
                          height: 44,
                          url: server.communityIcon(selectedCommunityId),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: selectedCommunityId.isEmpty ||
                        selectedCommunityName.isEmpty,
                    child: Icon(Icons.arrow_drop_down),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
