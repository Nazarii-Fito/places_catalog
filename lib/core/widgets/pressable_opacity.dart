import 'package:flutter/widgets.dart';

/// iOS-style tap feedback: the child fades while the finger is down.
///
/// Used instead of Material ink ripples, which look foreign on iOS.
/// When [onTap] is `null` the child is rendered as disabled (no feedback).
class PressableOpacity extends StatefulWidget {
  const PressableOpacity({
    super.key,
    required this.child,
    this.onTap,
    this.pressedOpacity = 0.6,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedOpacity;

  @override
  State<PressableOpacity> createState() => _PressableOpacityState();
}

class _PressableOpacityState extends State<PressableOpacity> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedOpacity(
        opacity: _pressed ? widget.pressedOpacity : 1,
        duration: Duration(milliseconds: _pressed ? 50 : 150),
        child: widget.child,
      ),
    );
  }
}
