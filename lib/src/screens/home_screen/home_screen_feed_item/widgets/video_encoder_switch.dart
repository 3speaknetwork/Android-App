import 'package:flutter/material.dart';

class VideoEncoderSwitch extends StatelessWidget {
  final ValueNotifier<bool> valueNotifier;

  const VideoEncoderSwitch({
    Key? key,
    required this.valueNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: valueNotifier,
        builder: (context, value, child) {
          return Switch(
            value: value,
            onChanged: (newValue) {
              valueNotifier.value = newValue; 
            },
            activeColor: Colors.blue, 
            inactiveThumbColor: Colors.grey,
          );
        },
      ),
    );
  }
}
