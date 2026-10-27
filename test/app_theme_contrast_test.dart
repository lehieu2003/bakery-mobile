import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('white text and icons on the brand pink meet WCAG AA (4.5:1)', () {
    expect(
      _contrast(Colors.white, AppTheme.primaryPink),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('brand pink text on the cream surfaces meets WCAG AA', () {
    expect(
      _contrast(AppTheme.primaryPink, AppTheme.canvasCream),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('muted secondary text meets WCAG AA on both cream surfaces', () {
    expect(
      _contrast(AppTheme.textMuted, AppTheme.canvasCream),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppTheme.textMuted, AppTheme.surfaceCream),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('the primary auth button uses the brand pink', () {
    expect(AppTheme.buttonPrimaryAuth, AppTheme.primaryPink);
  });
}
