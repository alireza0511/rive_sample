import 'package:flutter_test/flutter_test.dart';

import 'package:sample_rive_app/main.dart';
import 'package:sample_rive_app/rive_animations.dart';

void main() {
  testWidgets('lists the available animations', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Rive Animations'), findsOneWidget);
    for (final item in riveAnimations) {
      expect(find.text(item.title), findsOneWidget);
    }
  });
}
