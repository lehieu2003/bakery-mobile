import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/utils/image_url.dart';

/// Network image with the app's standard fallbacks: [url] may be a raw
/// server path (resolved against the API base URL) or absolute; an empty
/// url shows [emptyIcon], a failed load shows [errorIcon], both on a
/// [backgroundColor] box of the same size so layouts never jump.
///
/// Pass `emptyIcon: null` / `errorIcon: null` for a plain box, and
/// [placeholder] to replace the box entirely.
class AppNetworkImageWidget extends StatelessWidget {
  const AppNetworkImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.emptyIcon = Icons.image_outlined,
    this.errorIcon = Icons.broken_image_outlined,
    this.iconSize,
    this.iconColor,
    this.placeholder,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Defaults to `colorScheme.surfaceContainerHigh`.
  final Color? backgroundColor;
  final IconData? emptyIcon;
  final IconData? errorIcon;
  final double? iconSize;
  final Color? iconColor;

  /// Shown instead of the default box for both the empty and error cases.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    final image = resolved.isEmpty
        ? _fallback(context, emptyIcon)
        : Image.network(
            resolved,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, _, _) => _fallback(context, errorIcon),
          );
    final radius = borderRadius;
    return radius == null
        ? image
        : ClipRRect(borderRadius: radius, child: image);
  }

  Widget _fallback(BuildContext context, IconData? icon) {
    final custom = placeholder;
    if (custom != null) {
      return SizedBox(width: width, height: height, child: custom);
    }
    return Container(
      width: width,
      height: height,
      color:
          backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, size: iconSize, color: iconColor),
    );
  }
}
