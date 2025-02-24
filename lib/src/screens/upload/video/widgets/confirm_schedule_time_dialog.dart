import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmSceduleTimeDialog extends StatelessWidget {
  final DateTime dateTime;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onPickAgain;

  const ConfirmSceduleTimeDialog({
    Key? key,
    required this.dateTime,
    required this.onConfirm,
    required this.onCancel,
    required this.onPickAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('EEEE, MMMM d, y h:mm a').format(dateTime);

    return AlertDialog(
      title: const Text('Confirm Publish Time'),
      content: Text(
        'Are you sure you want to schedule your publish at:\n\n$formattedDate?',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onPickAgain,
          child: const Text('Pick Again'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
