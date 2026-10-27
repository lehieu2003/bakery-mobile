import 'package:bakery_mobile/src/features/pages/presentation/widgets/page_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the store page shows the shop hotline, same as the web', (
    tester,
  ) async {
    // Tall enough for the lazily built ListView to lay out the whole page.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuiltInPageBody(template: builtInPageTemplate('cua-hang')!),
        ),
      ),
    );

    // Meta rows are RichText: "<label>: <value>".
    expect(
      find.text('Điện thoại: 1900 779907', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('978 780 176', findRichText: true),
      findsNothing,
    );
  });
}
