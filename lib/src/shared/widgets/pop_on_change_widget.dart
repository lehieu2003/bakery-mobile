import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_durations.dart';

/// Gives [child] a short scale "pop" when [value] changes in a way
/// [popWhen] accepts (any change by default) — e.g. the cart badge when the
/// count goes up, the heart when it turns favorite. Nothing moves on first
/// build, so lists of already-favorite items do not all pop when a screen
/// opens, and nothing moves when the system asks for less motion.
class PopOnChangeWidget<T> extends StatefulWidget {
  const PopOnChangeWidget({
    super.key,
    required this.value,
    required this.child,
    this.popWhen,
    this.scale = 1.3,
  });

  final T value;
  final Widget child;

  /// Whether going from `previous` to `current` should pop.
  final bool Function(T previous, T current)? popWhen;

  /// Peak scale of the pop.
  final double scale;

  @override
  State<PopOnChangeWidget<T>> createState() => _PopOnChangeWidgetState<T>();
}

class _PopOnChangeWidgetState<T> extends State<PopOnChangeWidget<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.medium,
  );
  late Animation<double> _scale = _buildScale();

  Animation<double> _buildScale() => TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: widget.scale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: widget.scale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(PopOnChangeWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scale != widget.scale) _scale = _buildScale();
    if (oldWidget.value == widget.value) return;
    final shouldPop =
        widget.popWhen?.call(oldWidget.value, widget.value) ?? true;
    if (shouldPop && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
