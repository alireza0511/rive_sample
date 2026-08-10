import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart' as rive;
import 'package:sample_rive_app/animation_detail_screen.dart';
import 'package:sample_rive_app/rive_animations.dart';

/// The Rive ticker never goes idle, so `pumpAndSettle` would time out.
/// 30 frames ≈ 480ms, long enough to cover the 300ms tab transition.
Future<void> _pumpFrames(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpScreen(WidgetTester tester, RiveAnimationItem item) async {
  // Loading a Rive file is genuine async I/O, so it needs runAsync. The Rive
  // renderer cannot initialise in the headless test shell, hence Factory.flutter.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: AnimationDetailScreen(
          item: item,
          riveFactory: rive.Factory.flutter,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await _pumpFrames(tester);
}

List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data)
    .whereType<String>()
    .toList();

void main() {
  testWidgets('logs the loaded artboard and bound properties', (tester) async {
    final mood = riveAnimations.firstWhere((a) => a.title == 'Mood Interaction');
    await _pumpScreen(tester, mood);

    final texts = _visibleText(tester);
    expect(texts, contains('Loaded Mood Interaction'));
    expect(texts, contains('Watching 1 bound property'));
    expect(
      texts,
      contains('artboard "Artboard" · state machine "State Machine 1"'),
    );
  });

  testWidgets('driving a bound number logs the value change', (tester) async {
    final mood = riveAnimations.firstWhere((a) => a.title == 'Mood Interaction');
    await _pumpScreen(tester, mood);

    await tester.tap(find.textContaining('Controls'));
    await _pumpFrames(tester);
    expect(find.byType(Slider), findsOneWidget);

    final slider = tester.getRect(find.byType(Slider));
    await tester.dragFrom(
      slider.centerLeft + const Offset(20, 0),
      const Offset(150, 0),
    );
    await _pumpFrames(tester);
    expect(tester.widget<Slider>(find.byType(Slider)).value, greaterThan(0));

    await tester.tap(find.textContaining('Log ('));
    await _pumpFrames(tester);
    expect(_visibleText(tester), contains('Number 1'));
  });

  testWidgets('a file without a view model reports no data binding', (
    tester,
  ) async {
    final repost = riveAnimations.firstWhere(
      (a) => a.title == 'X Repost Redesign',
    );
    await _pumpScreen(tester, repost);

    expect(_visibleText(tester), contains('No data binding'));
    expect(find.text('Controls (0)'), findsOneWidget);
  });
}
