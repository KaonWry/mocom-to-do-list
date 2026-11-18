import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocom_to_do_list/main.dart';

void main() {
  testWidgets(
    'QuestRouletteApp loads and displays title and active badge count',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const QuestRouletteApp());
      await tester.pumpAndSettle();

      expect(find.text('Quest Roulette'), findsOneWidget);
      expect(find.text('QUEST AKTIF'), findsOneWidget);

      // Initial default quests has 3 active quests, verify badge shows 3
      final badgeFinder = find.widgetWithText(Badge, '3');
      expect(badgeFinder, findsWidgets);
    },
  );

  testWidgets('Opens centered Add Quest dialog and saves a new quest', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const QuestRouletteApp());
    await tester.pumpAndSettle();

    // Tap the floating action button "Quest Baru"
    await tester.tap(find.text('Quest Baru'));
    await tester.pumpAndSettle();

    // Verify dialog title is shown in the center dialog
    expect(find.text('Tambah Quest Baru'), findsOneWidget);
    expect(find.text('Simpan Quest'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Enter quest text
    await tester.enterText(find.byType(TextField), 'Test Centered Quest');
    await tester.pumpAndSettle();

    // Click "Simpan Quest"
    await tester.tap(find.text('Simpan Quest'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed and quest added to list
    expect(find.text('Tambah Quest Baru'), findsNothing);
    expect(find.text('Test Centered Quest'), findsOneWidget);

    // Now badge count should be 4
    expect(find.widgetWithText(Badge, '4'), findsWidgets);
  });

  testWidgets(
    'Spin button is disabled while a quest is critted, re-enabled after deleting it, and limited to 2 rolls per boss',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const QuestRouletteApp());
      await tester.pumpAndSettle();

      Finder spinButtonFinder() => find.ancestor(
        of: find.text('Spin'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );

      // Initially no quest is critted and 2/2 rolls left, so Spin button is enabled
      expect(find.textContaining('2/2 Roll'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(spinButtonFinder()).onPressed,
        isNotNull,
      );

      // 1st Crit Roll: Tap Spin and wait for the roulette timer to finish locking a quest
      await tester.tap(find.text('Spin'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Now a quest is critted (1/2 rolls left), so Spin button must be disabled
      expect(find.textContaining('1/2 Roll'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(spinButtonFinder()).onPressed,
        isNull,
      );

      // Delete all active quests (including the critted one) to clear the critted quest
      while (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
      }

      // Add a new quest so we can roll a 2nd time
      await tester.tap(find.text('Quest Baru'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Second Roll Quest');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Quest'));
      await tester.pumpAndSettle();

      // Once the critted quest is gone and 1/2 roll remains, Spin button is enabled again
      expect(
        tester.widget<ButtonStyleButton>(spinButtonFinder()).onPressed,
        isNotNull,
      );

      // 2nd Crit Roll: Tap Spin (with 1 active quest it locks immediately)
      await tester.tap(find.text('Spin'));
      await tester.pumpAndSettle();

      // Delete the 2nd critted quest
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Now 0/2 rolls remain for this boss fight, so Spin button stays disabled even with no critted quest
      expect(find.textContaining('0/2 Roll'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(spinButtonFinder()).onPressed,
        isNull,
      );
    },
  );
}
