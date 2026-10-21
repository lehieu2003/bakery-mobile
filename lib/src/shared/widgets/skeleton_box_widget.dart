import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

class SkeletonBoxWidget extends StatefulWidget {
  const SkeletonBoxWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBoxWidget> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBoxWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.warmBrown.withValues(alpha: 0.08);
    final highlight = AppTheme.surfaceCream.withValues(alpha: 0.85);

    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = (_controller.value * 2.4) - 1.2;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(offset - 1, 0),
                  end: Alignment(offset + 1, 0),
                  colors: [base, highlight, base],
                  stops: const [0.18, 0.5, 0.82],
                ),
              ),
              child: SizedBox(width: widget.width, height: widget.height),
            );
          },
        ),
      ),
    );
  }
}

Widget skeletonFillBuilder(BuildContext context, BoxConstraints constraints) {
  return SkeletonBoxWidget(
    width: constraints.maxWidth,
    height: constraints.maxHeight,
    borderRadius: 0,
  );
}
