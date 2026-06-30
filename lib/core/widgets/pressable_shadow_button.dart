// lib/core/widgets/pressable_shadow_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

class PressableShadowButton extends StatefulWidget {
  const PressableShadowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = AppColors.primary,
    this.shadowColor = AppColors.primaryPressed,
    this.radius = AppRadii.button,
    this.padding = const EdgeInsets.all(16),
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final double radius;
  final EdgeInsets padding;

  /// Fires a light haptic the instant the finger touches down (not on release).
  final bool haptic;

  @override
  State<PressableShadowButton> createState() => _PressableShadowButtonState();
}

class _PressableShadowButtonState extends State<PressableShadowButton> {
  bool _down = false;
  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _down != v) setState(() => _down = v);
  }

  void _onTapDown() {
    if (!_enabled) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    _set(true);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _down && _enabled;
    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: (_enabled && !pressed)
                ? [BoxShadow(color: widget.shadowColor, offset: const Offset(0, 4), blurRadius: 0)]
                : const [],
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
        ),
      ),
    );
  }
}
