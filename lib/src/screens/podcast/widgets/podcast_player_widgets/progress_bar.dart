import 'package:acela/src/screens/podcast/widgets/audio_player/action_tools.dart';
import 'package:flutter/material.dart';

class PodcastProgressBar extends StatefulWidget {
  const PodcastProgressBar(
      {required this.duration, required this.positionStream});

  final int? duration;
  final Stream<PositionData> positionStream;

  @override
  State<PodcastProgressBar> createState() => _PodcastProgressBarState();
}

class _PodcastProgressBarState extends State<PodcastProgressBar>
    with AutomaticKeepAliveClientMixin {
  double initialValue = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return StreamBuilder<PositionData>(
      stream: widget.positionStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        return SizedBox(
          height: 1.5,
          child: LinearProgressIndicator(
              color: theme.primaryColorLight, value: value(positionData)),
        );
      },
    );
  }

  double value(PositionData positionData) {
    double position = (positionData.position.inMilliseconds /
        positionData.duration.inMilliseconds);
    initialValue = position.isNaN ? initialValue : position;
    return position.isNaN
        ? initialValue
        : (positionData.position.inMilliseconds /
                positionData.duration.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();
  }

  @override
  bool get wantKeepAlive => true;
}
