import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  final String title;
  final String content;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsPadding: const EdgeInsets.only(bottom: 20, right: 20),
      title: Text(
        title,
      ),
      content: Text(
        content,
      ),
      actions: <Widget>[
        DialogButton(
            text: "No",
            onPressed: () {
              Navigator.pop(context);
            }),
        DialogButton(
          text: "Yes",
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
    );
  }
}

class DialogButton extends StatelessWidget {
  const DialogButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: TextButton(
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Theme.of(context).primaryColor),
          onPressed: onPressed,
          child: Text(
            text,
          )),
    );
  }
}
