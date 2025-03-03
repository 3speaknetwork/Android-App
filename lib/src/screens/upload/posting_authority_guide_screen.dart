import 'package:acela/src/utils/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PostingAuthorityGuideScreen extends StatelessWidget {
  const PostingAuthorityGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Posting authority"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kScreenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(context, "Step 1", "Open Keychain app."),
              const SizedBox(height: 8),
              text(context, "Step 2", "Open In-AppBrowser"),
              const SizedBox(height: 8),
              text(context, "Step 3", "Open ", [
                TextSpan(
                  text: "Peakd.com",
                  style: TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      var url = Uri.parse('https://peakd.com/');
                      launchUrl(url);
                    },
                ),
                TextSpan(
                  text: " & login with your account",
                ),
              ]),
              const SizedBox(height: 8),
              text(context, "Step 4", "Open Options menu by tapping on ..."),
              const SizedBox(height: 8),
              text(context, "Step 5", "Tap on Keys & Permissions."),
              const SizedBox(height: 8),
              Image.asset('assets/ps_guide_1.png'),
              const SizedBox(height: 8),
              text(context, "Step 6", "Add Threespeak as posting authority"),
              const SizedBox(height: 8),
              Image.asset('assets/ps_guide_2.png'),
            ],
          ),
        ),
      ),
    );
  }

  RichText text(BuildContext context, String boldText, String normalText,
      [List<InlineSpan>? textspans]) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          TextSpan(
            text: "$boldText: ",
            style: const TextStyle(fontWeight: FontWeight.bold), // Bold text
          ),
          TextSpan(text: normalText, children: textspans),
        ],
      ),
    );
  }
}
