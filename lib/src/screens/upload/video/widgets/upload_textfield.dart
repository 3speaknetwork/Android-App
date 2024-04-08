import 'package:acela/src/utils/constants.dart';
import 'package:flutter/material.dart';

class UploadTextField extends StatelessWidget {
  const UploadTextField(
      {Key? key,
      required this.textEditingController,
      required this.hintText,
      required this.labelText,
      this.maxLines,
      this.maxLength,
      this.minLines,
      required this.onChanged})
      : super(key: key);

  final TextEditingController textEditingController;
  final String hintText;
  final String labelText;
  final int? maxLines;
  final int? maxLength;
  final int? minLines;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: kScreenHorizontalPadding,
      child: TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          border: border(),
          filled: true,
          isDense: true,
          fillColor: theme.cardColor,
          hintText: hintText,
          labelText: labelText,
          suffixIcon: _clearButton(),
        ),
        onChanged: onChanged,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
      ),
    );
  }

  ValueListenableBuilder<TextEditingValue> _clearButton() {
    return ValueListenableBuilder(
      valueListenable: textEditingController,
      builder: (context, value, child) {
        return Visibility(
            visible: textEditingController.text.isNotEmpty, child: child!);
      },
      child: IconButton(
        splashRadius: 15,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          onChanged('');
          textEditingController.clear();
        },
        icon: const Icon(
          Icons.cancel,
          size: 20,
        ),
      ),
    );
  }

  OutlineInputBorder border() => OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(4)));
}
