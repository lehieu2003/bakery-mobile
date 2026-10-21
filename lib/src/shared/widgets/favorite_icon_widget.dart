import 'package:flutter/material.dart';

/// Wishlist heart: filled red when [isFavorite], outlined otherwise, and a
/// small spinner of the same footprint while the toggle is [isPending].
/// Wrap it in the button that fits the context (IconButton, card overlay).
class FavoriteIconWidget extends StatelessWidget {
  const FavoriteIconWidget({
    super.key,
    required this.isFavorite,
    this.isPending = false,
    this.size = 24,
    this.outlineColor,
  });

  final bool isFavorite;
  final bool isPending;
  final double size;

  /// Color of the outlined heart; defaults to the ambient icon color.
  final Color? outlineColor;

  static const Color activeColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      final spinner = size * 0.75;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: spinner,
            height: spinner,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      size: size,
      color: isFavorite ? activeColor : outlineColor,
    );
  }
}
