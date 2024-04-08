import 'package:flutter/material.dart';

class CommentSearchBar extends StatefulWidget {
  const CommentSearchBar(
      {required this.onChanged,
      required this.textEditingController,
      required this.showSearchBar});

  final Function(String value) onChanged;
  final TextEditingController textEditingController;
  final ValueNotifier<bool> showSearchBar;
  @override
  State<CommentSearchBar> createState() => _CommentSearchBarState();
}

class _CommentSearchBarState extends State<CommentSearchBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = outLineBorder();
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
        valueListenable: widget.showSearchBar,
        builder: (context, showSearchBar, child) {
          if (showSearchBar) {
            _focusNode.requestFocus();
          } else {
            _focusNode.unfocus();
          }
          return PopScope(
            canPop: !showSearchBar,
            onPopInvoked: (didPop) {
              if (showSearchBar) {
                _onClear();
                return;
              }
            },
            child: Column(
              children: [
                AnimatedContainer(
                    height: showSearchBar ? 50 : 0,
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.only(
                        left: 8, right: 8, top: 8, bottom: 4),
                    child: child!),
                Visibility(visible: showSearchBar, child: Divider()),
              ],
            ),
          );
        },
        child: TextField(
          focusNode: _focusNode,
          controller: widget.textEditingController,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            prefixIcon: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.search,
                ),
              ),
            ),
            hintText: "Search for comment, username",
            suffixIcon: getSuffixIcon(theme),
            fillColor: Theme.of(context).primaryColorDark,
            filled: true,
            contentPadding: const EdgeInsets.only(bottom: 13),
            border: border,
            focusedBorder: border,
            enabledBorder: border,
            disabledBorder: border,
          ),
        ));
  }

  OutlineInputBorder outLineBorder() {
    return const OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.all(Radius.circular(4)));
  }

  Widget getSuffixIcon(ThemeData theme) {
    return IconButton(
        splashRadius: 15,
        onPressed: () {
          _onClear();
        },
        icon: Text('Done'));
  }

  void _onClear() {
    _focusNode.unfocus();
    widget.showSearchBar.value = false;
    widget.textEditingController.clear();
    widget.onChanged("");
  }
}
