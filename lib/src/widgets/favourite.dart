import 'package:flutter/material.dart';

class FavouriteWidget extends StatefulWidget {
  const FavouriteWidget(
      {Key? key,
      required this.isLiked,
      required this.onAdd,
      required this.onRemove,
      this.iconColor,
      this.iconSize,
      this.alignment,
      this.disablePadding = false,
      required this.toastType})
      : super(key: key);

  final bool isLiked;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Color? iconColor;
  final bool disablePadding;
  final String toastType;
  final double? iconSize;
  final Alignment? alignment;

  @override
  State<FavouriteWidget> createState() => _FavouriteWidgetState();
}

class _FavouriteWidgetState extends State<FavouriteWidget> {
  late bool isLiked;
  @override
  void initState() {
    isLiked = widget.isLiked;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FavouriteWidget oldWidget) {
    isLiked = widget.isLiked;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      alignment:widget.alignment ,
      constraints: widget.disablePadding ? BoxConstraints() : null,
      padding: widget.disablePadding ? EdgeInsets.zero : null,
      icon: Icon(
        isLiked ? Icons.bookmark : Icons.bookmark_border,
        size: widget.iconSize,
        color: widget.iconColor,
      ),
      onPressed: () {
        if (isLiked) {
          widget.onRemove();
          setState(() {
            isLiked = false;
          });
          showSnackBar(false);
        } else {
          widget.onAdd();
          setState(() {
            isLiked = true;
          });
          showSnackBar(true);
        }
      },
    );
  }

  void showSnackBar(bool isAdding) {
    final String message = isAdding
        ? "is added to your bookmarks"
        : "is removed from your bookmarks";
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        'The ${widget.toastType} $message',
        style: TextStyle(color: Colors.white),
      ),
      duration: Duration(seconds: 3),
    ));
  }
}
