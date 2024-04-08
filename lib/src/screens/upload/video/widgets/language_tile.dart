import 'package:acela/src/screens/settings/settings_screen.dart';
import 'package:acela/src/utils/constants.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';

class LanguageTile extends StatefulWidget {
  const LanguageTile(
      {Key? key, required this.selectedLanguage, required this.onChanged})
      : super(key: key);

  final VideoLanguage selectedLanguage;
  final Function(VideoLanguage) onChanged;

  @override
  State<LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<LanguageTile> {
  late VideoLanguage selectedLanguage;
  var languages = [
    VideoLanguage(code: "en", name: "English"),
    VideoLanguage(code: "de", name: "Deutsch"),
    VideoLanguage(code: "pt", name: "Portuguese"),
    VideoLanguage(code: "fr", name: "Français"),
    VideoLanguage(code: "es", name: "Español"),
    VideoLanguage(code: "nl", name: "Nederlands"),
    VideoLanguage(code: "ko", name: "한국어"),
    VideoLanguage(code: "ru", name: "русский"),
    VideoLanguage(code: "hu", name: "Magyar"),
    VideoLanguage(code: "ro", name: "Română"),
    VideoLanguage(code: "cs", name: "čeština"),
    VideoLanguage(code: "pl", name: "Polskie"),
    VideoLanguage(code: "in", name: "bahasa Indonesia"),
    VideoLanguage(code: "bn", name: "বাংলা"),
    VideoLanguage(code: "it", name: "Italian"),
    VideoLanguage(code: "he", name: "עִברִית"),
  ];

  @override
  void initState() {
    selectedLanguage = widget.selectedLanguage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: kScreenHorizontalPadding,
      leading: const Icon(Icons.language),
      title: const Text("Set Language Filter"),
      trailing: Text(selectedLanguage.name),
      onTap: () {
        tappedLanguage();
      },
    );
  }

  void tappedLanguage() {
    showAdaptiveActionSheet(
      context: context,
      title: const Text('Set Default Language Filter'),
      androidBorderRadius: 30,
      actions: languages.map((e) => getLangAction(e)).toList(),
      cancelAction: CancelAction(title: const Text('Cancel')),
    );
  }

  BottomSheetAction getLangAction(VideoLanguage language) {
    return BottomSheetAction(
      title: Text(language.name),
      onPressed: (context) async {
        widget.onChanged(language);
        setState(() {
          selectedLanguage = language;
          Navigator.of(context).pop();
        });
      },
    );
  }
}
