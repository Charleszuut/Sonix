import 'package:flutter/material.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    required this.onChanged,
  });

  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final total =
        duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final current = position.inMilliseconds.clamp(0, duration.inMilliseconds);
    final buffered =
        bufferedPosition.inMilliseconds.clamp(0, duration.inMilliseconds);

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            LinearProgressIndicator(
              value: buffered / total,
              minHeight: 4,
              backgroundColor: Colors.white24,
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 0,
                max: total,
                value: current.toDouble().clamp(0, total),
                onChanged: (value) =>
                    onChanged(Duration(milliseconds: value.round())),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(position)),
              Text(_format(duration)),
            ],
          ),
        ),
      ],
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
