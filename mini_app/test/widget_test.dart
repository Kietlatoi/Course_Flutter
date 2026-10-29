// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_app/main.dart';
import 'package:mini_app/game.dart';

void main() {
  testWidgets('Displays Birdle title and five rows of empty tiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Birdle'), findsOneWidget);
    expect(find.byType(GuessInput), findsOneWidget);
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

  testWidgets('Guesses update consecutive rows and preserve input focus', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    final input = find.byType(TextField);
    final controller = tester.widget<TextField>(input).controller;

    for (final word in ['ABHOR', 'abide']) {
      await tester.enterText(input, word);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    final tiles = tester.widgetList<Tile>(find.byType(Tile)).toList();
    expect(tiles.take(10).map((tile) => tile.letter).join(), 'abhorabide');
    expect(
      tiles.take(10).every((tile) => tile.hitType != HitType.none),
      isTrue,
    );
    expect(tiles.skip(10).every((tile) => tile.letter.isEmpty), isTrue);
    expect(tester.widget<TextField>(input).controller, same(controller));
    expect(controller!.text, isEmpty);
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invalid guesses and a sixth guess do not change the board', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();
    final input = find.byType(TextField);

    for (final word in ['', 'abc', 'zzzzz']) {
      await tester.enterText(input, word);
      await tester.tap(find.byIcon(Icons.arrow_circle_up));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Tile>(find.byType(Tile))
            .every((tile) => tile.letter.isEmpty),
        isTrue,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    }

    for (var turn = 0; turn < 5; turn++) {
      await tester.enterText(input, 'abhor');
      await tester.tap(find.byIcon(Icons.arrow_circle_up));
      await tester.pumpAndSettle();
    }
    await tester.enterText(input, 'abide');
    await tester.tap(find.byIcon(Icons.arrow_circle_up));
    await tester.pumpAndSettle();

    final letters = tester
        .widgetList<Tile>(find.byType(Tile))
        .map((tile) => tile.letter)
        .join();
    expect(letters, List.filled(5, 'abhor').join());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tile animates its background and displays uppercase letters', (
    tester,
  ) async {
    Color? backgroundColor() {
      final decoration = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(Tile),
          matching: find.byType(DecoratedBox),
        ),
      );
      return (decoration.decoration as BoxDecoration).color;
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tile(letter: '', hitType: HitType.none),
        ),
      ),
    );
    expect(backgroundColor(), Colors.white);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tile(letter: 'a', hitType: HitType.hit),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(backgroundColor(), Colors.white);
    await tester.pump(const Duration(milliseconds: 250));
    expect(backgroundColor(), isNot(Colors.white));
    expect(backgroundColor(), isNot(Colors.green));
    await tester.pump(const Duration(milliseconds: 250));
    expect(backgroundColor(), Colors.green);
    expect(tester.takeException(), isNull);
  });

  for (final useButton in [false, true]) {
    testWidgets(
      'Submits trimmed text using ${useButton ? 'button' : 'keyboard'}',
      (tester) async {
        final guesses = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: GuessInput(onSubmitGuess: guesses.add)),
          ),
        );
        await tester.pumpAndSettle();
        final input = find.byType(TextField);
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

        await tester.enterText(input, ' ab ');
        if (useButton) {
          await tester.tap(find.byIcon(Icons.arrow_circle_up));
        } else {
          await tester.testTextInput.receiveAction(TextInputAction.done);
        }
        await tester.pumpAndSettle();

        expect(guesses, ['ab']);
        expect(tester.widget<TextField>(input).controller!.text, isEmpty);
        expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);

        await tester.enterText(input, 'abcdef');
        expect(tester.widget<TextField>(input).controller!.text, 'abcde');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
