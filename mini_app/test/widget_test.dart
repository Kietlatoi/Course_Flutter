// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mini_app/main.dart';
import 'package:mini_app/game.dart';

void main() {
  testWidgets('Displays Birdle title and five rows of empty tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Birdle'), findsOneWidget);
    expect(find.byType(Tile), findsNWidgets(25));
    final tiles = tester.widgetList<Tile>(find.byType(Tile)).toList();
    expect(
      tiles.every(
        (tile) => tile.letter.isEmpty && tile.hitType == HitType.none,
      ),
      isTrue,
    );
    for (var row = 0; row < 5; row++) {
      final first = tester.getTopLeft(find.byType(Tile).at(row * 5));
      final last = tester.getTopLeft(find.byType(Tile).at(row * 5 + 4));
      expect(last.dy, first.dy);
      expect(last.dx - first.dx, 260);
      if (row > 0) {
        final previous = tester.getTopLeft(find.byType(Tile).at((row - 1) * 5));
        expect(first.dy - previous.dy, 65);
      }
    }
    expect(tester.takeException(), isNull);
  });
}
