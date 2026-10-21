import 'package:flutter/material.dart';

/// Centered progress indicator — the app's standard "loading" state.
/// [size] sets a fixed square for inline/footers (with a thinner stroke);
/// null keeps the Material default.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.size, this.padding = EdgeInsets.zero});

  final double? size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final side = size;
    return Padding(
      padding: padding,
      child: Center(
        child: side == null
            ? const CircularProgressIndicator()
            : SizedBox(
                width: side,
                height: side,
                child: const CircularProgressIndicator(strokeWidth: 2.5),
              ),
      ),
    );
  }
}
