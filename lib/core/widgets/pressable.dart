import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/motion.dart';

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap:
          widget.onTap == null
              ? null
              : () {
                if (widget.haptic) {
                  HapticFeedback.lightImpact();
                }
                widget.onTap!();
              },
      child:
          disableAnimations
              ? widget.child
              : AnimatedScale(
                scale: _down ? widget.scale : 1.0,
                duration: Motion.press,
                curve: Curves.easeOut,
                child: widget.child,
              ),
    );
  }
}
