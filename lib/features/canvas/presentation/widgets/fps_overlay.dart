import 'dart:collection';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

/// Displays current FPS using a Ticker to track frame timestamps
class FpsOverlay extends StatefulWidget {
  const FpsOverlay({super.key});

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final Queue<Duration> _frameTimes = Queue();
  double _fps = 0;
  Duration _lastTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _frameTimes.add(elapsed);

    // Keep a rolling 1-second window
    while (_frameTimes.isNotEmpty &&
        elapsed - _frameTimes.first > const Duration(seconds: 1)) {
      _frameTimes.removeFirst();
    }

    if (elapsed - _lastTime > const Duration(milliseconds: 200)) {
      _lastTime = elapsed;
      setState(() {
        _fps = _frameTimes.length.toDouble();
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Color get _fpsColor {
    if (_fps >= 55) return const Color(0xFF4CAF50);
    if (_fps >= 30) return const Color(0xFFFF9800);
    return const Color(0xFFCF6679);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _fpsColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 14, color: _fpsColor),
            const SizedBox(width: 5),
            Text(
              '${_fps.toStringAsFixed(0)} FPS',
              style: TextStyle(
                color: _fpsColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
