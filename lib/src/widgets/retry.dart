import 'package:flutter/material.dart';

class RetryScreen extends StatelessWidget {
  const RetryScreen({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  final Function() onRetry;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          Text(error)
        ],
      ),
    );
  }
}
