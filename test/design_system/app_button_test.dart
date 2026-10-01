import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/design_system/design_system.dart';

void main() {
  group('AppButton', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Start workout',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start workout'));
      expect(pressed, isTrue);
    });

    testWidgets('shows a loading indicator and ignores taps while loading', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Start workout',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Start workout'));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('does nothing when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(label: 'Start workout', onPressed: null),
          ),
        ),
      );

      // Tapping a disabled button must not throw.
      await tester.tap(find.text('Start workout'));
      await tester.pump();
    });
  });
}
