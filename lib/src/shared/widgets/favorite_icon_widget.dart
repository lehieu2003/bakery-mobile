import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/pop_on_change_widget.dart';

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

  static const Color activeColor = AppTheme.favoriteActive;

  @override
  Widget build(BuildContext context) {
    // Pops when the heart turns on; kept around the spinner too, so the
    // false → pending → true sequence of a toggle still reads as a change.
    return PopOnChangeWidget<bool>(
      value: isFavorite,
      popWhen: (wasFavorite, nowFavorite) => !wasFavorite && nowFavorite,
      child: _buildIcon(),
    );
  }

  Widget _buildIcon() {
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
