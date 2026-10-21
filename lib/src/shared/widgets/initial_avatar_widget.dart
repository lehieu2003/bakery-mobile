import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Circle avatar showing the first letter of [name] (uppercased), or
/// [fallback] when the name is empty. Defaults: brand pink, white letter.
class InitialAvatarWidget extends StatelessWidget {
  const InitialAvatarWidget({
    super.key,
    required this.name,
    this.radius = 20,
    this.backgroundColor = AppTheme.primaryPink,
    this.foregroundColor = Colors.white,
    this.fallback = '?',
  });

  final String? name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final String fallback;

  /// First letter of [name], uppercased; [fallback] when blank.
  static String initialOf(String? name, {String fallback = '?'}) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Text(
        initialOf(name, fallback: fallback),
        style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.w700),
      ),
    );
  }
}
