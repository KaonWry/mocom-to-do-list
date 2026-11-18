import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocom_to_do_list/main.dart';

void main() {
  testWidgets('QuestRouletteApp loads and displays title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const QuestRouletteApp());
    await tester.pumpAndSettle();

    expect(find.text('Quest Roulette'), findsOneWidget);
    expect(find.text('QUEST AKTIF'), findsOneWidget);
  });

  testWidgets('Opens centered Add Quest dialog and saves a new quest', (WidgetTester tester) async {
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
  });
}
