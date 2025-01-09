import 'package:acela/src/extensions/ui.dart';
import 'package:acela/src/screens/login/provider/logout_provider.dart';
import 'package:acela/src/screens/report/controller/report_controller.dart';
import 'package:acela/src/screens/report/model/report/report_post.dart';
import 'package:acela/src/screens/report/model/report_user_model.dart';
import 'package:acela/src/screens/report/widgets/responsive_scroll_dialog.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ReportPostDialog extends StatefulWidget {
  const ReportPostDialog(
      {super.key,
      this.title,
      required this.reportType,
      this.permlink,
      required this.author,
      required this.rootContext,
      required this.onSuccessRemove})
      : assert(!(reportType == Report.post && permlink == null),
            "permlink is required to report a reply");

  final Report reportType;
  final String author;
  final String? permlink;
  final BuildContext rootContext;
  final Function(Report reportType) onSuccessRemove;
  final String? title;

  @override
  State<ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<ReportPostDialog> {
  late ThemeData theme;

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScrollDialog(
      title: title,
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Text(
                "Please select the option that best describes the problem"),
          ),
          _actionButton(
            "Spam",
          ),
          _actionButton("Abuse"),
          _actionButton("Harassment"),
          _actionButton("Harmful misinforment"),
          _actionButton("Glorifying Violence"),
          _actionButton("Exposing Info"),
          _actionButton("Cancel", isCancel: true),
        ],
      ),
    );
  }

  String get title {
    if (widget.title != null) {
      return widget.title!;
    } else if (widget.reportType == Report.user) {
      return "Report user";
    } else {
      return "Report message";
    }
  }

  Widget _actionButton(String text, {bool isCancel = false}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          side: BorderSide(
              color: theme.primaryColorDark.withOpacity(0.3), width: 0.7),
          backgroundColor: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
        ),
        onPressed: () {
          Navigator.pop(context);
          if (!isCancel) {
            widget.rootContext.showLoader();
            if (widget.reportType == Report.post) {
              _reportReply(text);
            } else {
              _reportUser(text);
            }
          }
        },
        child: Text(
          text,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _reportReply(String text) {
    context.read<ReportController>().reportReply(
      ReportPostModel(
          permlink: widget.permlink!, reason: text, username: widget.author),
      onSuccess: _onSuccess,
      onFailure: _onFailure,
      onLogout: _onLogout,
      showToast: (message) {
        widget.rootContext.showSnackBar(message);
      },
    );
  }

  void _onLogout() {
      LogoutProvider().call();
    }

  void _reportUser(String text) {
    context.read<ReportController>().reportUser(
      ReportUserModel(reason: text, username: widget.author),
      onSuccess: _onSuccess,
      onFailure: _onFailure,
      onLogout: _onLogout,
      showToast: (message) {
        widget.rootContext.showSnackBar(message);
      },
    );
  }

  void _onFailure() {
    widget.rootContext.hideLoader();
  }

  void _onSuccess() {
    widget.rootContext.hideLoader();

    widget.onSuccessRemove(widget.reportType);
  }
}
