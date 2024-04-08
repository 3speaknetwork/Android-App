import 'package:acela/src/utils/constants.dart';
import 'package:flutter/material.dart';

class RewardTypeWidget extends StatefulWidget {
  const RewardTypeWidget(
      {Key? key, required this.isPower100, required this.onChanged})
      : super(key: key);

  final bool isPower100;
  final Function(bool) onChanged;

  @override
  State<RewardTypeWidget> createState() => _RewardTypeWidgetState();
}

class _RewardTypeWidgetState extends State<RewardTypeWidget> {
  late bool isPower100;

  @override
  void initState() {
    isPower100 = widget.isPower100;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kScreenHorizontalPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isPower100 ? '100% power' : '50% power'),
          Switch(
            value: isPower100,
            onChanged: (newValue) {
              setState(() {
                isPower100 = newValue;
              });
              widget.onChanged(newValue);
            },
          )
        ],
      ),
    );
  }
}
