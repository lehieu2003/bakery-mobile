import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/pop_on_change_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _counter(int value, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduceMotion),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: PopOnChangeWidget<int>(
      value: value,
      popWhen: (previous, current) => current > previous,
      child: Text('$value'),
    ),
  ),
);

Widget _heart({required bool favorite, bool pending = false}) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: FavoriteIconWidget(isFavorite: favorite, isPending: pending),
  ),
);

double _scale(WidgetTester tester) => tester
    .widget<ScaleTransition>(find.byType(ScaleTransition).first)
    .scale
    .value;

/// Pumps to the middle of the pop, where the scale is above 1 if it popped.
Future<void> _midPop(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.medium * 0.4);
}

void main() {
  testWidgets('nothing moves on first build', (tester) async {
    await tester.pumpWidget(_counter(3));
    await _midPop(tester);
    expect(_scale(tester), 1);
  });

  testWidgets('pops when the value changes the accepted way, then settles', (
    tester,
  ) async {
    await tester.pumpWidget(_counter(1));
    await tester.pumpWidget(_counter(2));
    await _midPop(tester);
    expect(_scale(tester), greaterThan(1.2));

    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('stays still when popWhen rejects the change', (tester) async {
    await tester.pumpWidget(_counter(2));
    await tester.pumpWidget(_counter(1));
    await _midPop(tester);
    expect(_scale(tester), 1);
  });

  testWidgets('stays still when the system asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(_counter(1, reduceMotion: true));
    await tester.pumpWidget(_counter(2, reduceMotion: true));
    await _midPop(tester);
    expect(_scale(tester), 1);
  });

  group('FavoriteIconWidget', () {
    testWidgets('pops when a toggle turns it on, through the spinner', (
      tester,
    ) async {
      await tester.pumpWidget(_heart(favorite: false));
      await tester.pumpWidget(_heart(favorite: false, pending: true));
      await tester.pump();
      await tester.pumpWidget(_heart(favorite: true));
      await _midPop(tester);
      expect(_scale(tester), greaterThan(1.2));
      await tester.pumpAndSettle();
    });

    testWidgets('does not pop when turned off', (tester) async {
      await tester.pumpWidget(_heart(favorite: true));
      await tester.pumpWidget(_heart(favorite: false));
      await _midPop(tester);
      expect(_scale(tester), 1);
    });
  });
}
