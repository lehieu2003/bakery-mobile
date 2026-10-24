import 'package:flutter/material.dart';

/// Member-tier pill colors, copied from the web admin `MEMBER_LEVEL_COLORS`
/// (Tailwind hex) so mobile matches the web list.
class _MemberLevelStyle {
  const _MemberLevelStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

const _silverStyle = _MemberLevelStyle(
  background: Color(0xFFF1F5F9),
  foreground: Color(0xFF475569),
  border: Color(0xFFE2E8F0),
);

const _goldStyle = _MemberLevelStyle(
  background: Color(0xFFFFFBEB),
  foreground: Color(0xFFB45309),
  border: Color(0xFFFDE68A),
);

const _platinumStyle = _MemberLevelStyle(
  background: Color(0xFFFDF2F8),
  foreground: Color(0xFFBE185D),
  border: Color(0xFFFBCFE8),
);

/// Fallback for levels outside the 3 known ones (server may add tiers
/// before the app ships) — neutral grey.
const _neutralStyle = _MemberLevelStyle(
  background: Color(0xFFF3F4F6),
  foreground: Color(0xFF4B5563),
  border: Color(0xFFE5E7EB),
);

/// Pill showing the customer's loyalty tier. The label keeps the raw server
/// code (SILVER / GOLD / PLATINUM) like the web admin; unknown codes render
/// in neutral grey.
class MemberLevelBadge extends StatelessWidget {
  const MemberLevelBadge({super.key, required this.level});

  /// Uppercase member level from the server, e.g. `GOLD`.
  final String level;

  @override
  Widget build(BuildContext context) {
    final style = switch (level) {
      'SILVER' => _silverStyle,
      'GOLD' => _goldStyle,
      'PLATINUM' => _platinumStyle,
      _ => _neutralStyle,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: style.foreground,
        ),
      ),
    );
  }
}
