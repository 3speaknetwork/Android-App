import 'package:acela/src/utils/constants.dart';
import 'package:acela/src/utils/enum.dart';
import 'package:flutter/material.dart';

class UploadProgressExpandableTile extends StatefulWidget {
  const UploadProgressExpandableTile(
      {Key? key,
      required this.onUpload,
      required this.mediaUploadProgress,
      required this.thumbnailUploadProgress,
      required this.finalUploadProgress,
      required this.uploadStatus,
      required this.pageController,
      required this.currentPage,
      required this.isLocalEncode})
      : super(key: key);

  final Function() onUpload;
  final int currentPage;
  final ValueNotifier<double> mediaUploadProgress;
  final ValueNotifier<double> thumbnailUploadProgress;
  final ValueNotifier<double> finalUploadProgress;
  final ValueNotifier<UploadStatus> uploadStatus;
  final PageController pageController;
  final bool isLocalEncode;

  @override
  State<UploadProgressExpandableTile> createState() =>
      _UploadProgressExpandableTileState();
}

class _UploadProgressExpandableTileState
    extends State<UploadProgressExpandableTile> {
  late int _pageIndex;
  bool isExpanded = false;

  @override
  void initState() {
    _pageIndex = widget.currentPage;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.onUpload();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kScreenHorizontalPadding,
      child: ExpansionPanelList(
        expandedHeaderPadding: const EdgeInsets.only(top: 0),
        elevation: 0,
        expansionCallback: (int index, bool isExpanded) {
          setState(
            () {
              this.isExpanded = isExpanded;
            },
          );
        },
        children: [
          ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return SizedBox(
                height: 55,
                child: Stack(
                  children: [
                    PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) {
                        setState(
                          () {
                            _pageIndex = value;
                          },
                        );
                      },
                      controller: widget.pageController,
                      scrollDirection: Axis.vertical,
                      children: _uploadWidgets(
                          showStartEndWidgets: true, showWidgets: !isExpanded),
                    ),
                    Visibility(
                      visible: isExpanded,
                      child: ValueListenableBuilder<UploadStatus>(
                        valueListenable: widget.uploadStatus,
                        builder: (context, uploadStatus, child) {
                          return ListTile(
                            title: Text(
                              uploadStatusString(uploadStatus),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            body: Column(
              children:
                  _uploadWidgets(showStartEndWidgets: false, showWidgets: true),
            ),
            isExpanded: isExpanded,
          ),
        ],
      ),
    );
  }

  String uploadStatusString(UploadStatus status) {
    if (status == UploadStatus.idle) {
      return "Waiting to Upload";
    } else if (status == UploadStatus.started) {
      return "Uploading (${(_pageIndex)}/${widget.isLocalEncode ? 3 : 4})";
    } else {
      return "Upload Complete";
    }
  }

  List<Widget> _uploadWidgets(
      {required bool showStartEndWidgets, required bool showWidgets}) {
    return [
      Visibility(
        visible: showStartEndWidgets && showWidgets,
        child: ListTile(
            leading: !isExpanded
                ? _progessIndicator(showBacgroundColor: false)
                : null,
            title: Text('Waiting to upload'),
            trailing: isExpanded
                ? _progessIndicator(showBacgroundColor: false)
                : null),
      ),
      Visibility(
        visible: showWidgets,
        child: ListTile(
            leading: videoUploadProgressWidget(!isExpanded),
            title: Text(widget.isLocalEncode ? "Video Encode" : 'Video Upload'),
            trailing: videoUploadProgressWidget(isExpanded)),
      ),
      Visibility(
        visible: showWidgets,
        child: ListTile(
            leading: fetchingVideoThumbnailProgressWidget(!isExpanded),
            title: const Text('Fetching Video Thumbnail'),
            trailing: fetchingVideoThumbnailProgressWidget(isExpanded)),
      ),
      if (!widget.isLocalEncode)
        Visibility(
          visible: showWidgets,
          child: ListTile(
              leading: thumbnailUploadProgressWidget(!isExpanded),
              title: Text('Thumbnail Upload'),
              trailing: thumbnailUploadProgressWidget(isExpanded)),
        ),
      Visibility(
        visible: showWidgets,
        child: ListTile(
            leading: moveWidgetToEncodingQueueProgressWidget(!isExpanded),
            title: Text(widget.isLocalEncode
                ? "Video Upload"
                : 'Preparing for Encoding'),
            trailing: moveWidgetToEncodingQueueProgressWidget(isExpanded)),
      ),
      Visibility(
        visible: showStartEndWidgets && showWidgets,
        child: ListTile(
          leading: !isExpanded
              ? const Icon(Icons.check, color: Colors.lightGreen)
              : null,
          title: Text('Upload Complete'),
          trailing: isExpanded
              ? const Icon(Icons.check, color: Colors.lightGreen)
              : null,
        ),
      ),
    ];
  }

  Widget? videoUploadProgressWidget(bool isVisible) {
    if (!isVisible) {
      return null;
    } else if (_pageIndex < 1) {
      return const Icon(Icons.pending);
    } else if (_pageIndex == 1) {
      return ValueListenableBuilder<double>(
        valueListenable: widget.mediaUploadProgress,
        builder: (context, progress, child) {
          return _progessIndicator(progress: progress);
        },
      );
    } else {
      return const Icon(Icons.check, color: Colors.lightGreen);
    }
  }

  Widget? fetchingVideoThumbnailProgressWidget(bool isVisible) {
    if (!isVisible) {
      return null;
    } else if (_pageIndex < 2) {
      return const Icon(Icons.pending);
    } else {
      if (_pageIndex == 2) {
        return _progessIndicator(showBacgroundColor: false);
      } else {
        return const Icon(Icons.check, color: Colors.lightGreen);
      }
    }
  }

  Widget? thumbnailUploadProgressWidget(bool isVisible) {
    if (!isVisible) {
      return null;
    } else if (_pageIndex < 3) {
      return const Icon(Icons.pending);
    } else {
      if (_pageIndex == 3) {
        return ValueListenableBuilder<double>(
          valueListenable: widget.thumbnailUploadProgress,
          builder: (context, progress, child) {
            return _progessIndicator(progress: progress);
          },
        );
      } else {
        return const Icon(Icons.check, color: Colors.lightGreen);
      }
    }
  }

  Widget? moveWidgetToEncodingQueueProgressWidget(bool isVisible) {
    int pageIndex = widget.isLocalEncode ? 3 : 4;
    if (!isVisible) {
      return null;
    } else if (_pageIndex < pageIndex) {
      return const Icon(Icons.pending);
    } else {
      if (_pageIndex == pageIndex) {
        if (widget.isLocalEncode) {
          return ValueListenableBuilder<double>(
            valueListenable: widget.finalUploadProgress,
            builder: (context, progress, child) {
              return _progessIndicator(progress: progress);
            },
          );
        } else {
          return _progessIndicator(showBacgroundColor: false);
        }
      } else {
        return const Icon(Icons.check, color: Colors.lightGreen);
      }
    }
  }

  Widget _progessIndicator({double? progress, bool showBacgroundColor = true}) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 25,
      width: 25,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        value: progress,
        valueColor: AlwaysStoppedAnimation<Color?>(theme.primaryColorLight),
        backgroundColor: showBacgroundColor
            ? theme.primaryColorLight.withOpacity(0.4)
            : null,
      ),
    );
  }
}
