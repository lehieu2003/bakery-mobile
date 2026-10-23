import 'package:flutter/widgets.dart';

/// Whether auto-advancing content (carousels) may move on its own: not when
/// the user asked the system for less motion, nor with a screen reader on —
/// content changing under VoiceOver/TalkBack focus is disorienting
/// (WCAG 2.2.2 Pause, Stop, Hide).
bool allowsAutoplay(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context) &&
    !MediaQuery.accessibleNavigationOf(context);
