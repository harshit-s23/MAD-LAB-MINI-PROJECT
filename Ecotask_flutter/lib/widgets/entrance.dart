import 'dart:async';

import 'package:flutter/material.dart';

/// Fade + slide + scale entrance (Framer Motion `initial` -> `animate`).
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = Offset.zero,
    this.beginScale = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting translation in logical pixels.
  final Offset offset;
  final double beginScale;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
                scale: widget.beginScale + (1 - widget.beginScale) * t,
                child: child),
          ),
        );
      },
    );
  }
}

/// `animate-float`: gentle 8px vertical bob (6s cycle).
class FloatingEmoji extends StatefulWidget {
  const FloatingEmoji(this.emoji, {super.key, this.size = 36});

  final String emoji;
  final double size;

  @override
  State<FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<FloatingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, -8 * _curve.value),
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
      ),
    );
  }
}
