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
}
