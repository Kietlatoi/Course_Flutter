import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolodex/main.dart';
import 'package:rolodex/screens/contacts.dart';

void main() {
  testWidgets('Adapts across the 600 pixel breakpoint when resized', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(const RolodexApp());
    expect(find.byType(CupertinoApp), findsOneWidget);

    for (final width in [390.0, 600.0, 601.0, 1200.0, 390.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpAndSettle();
      if (width > 600) {
        expect(find.byType(ContactListsPage), findsOneWidget);
        expect(find.byType(CupertinoSearchTextField), findsOneWidget);
        final sidebar = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.width == 320,
        );
        expect(tester.getSize(sidebar).width, 320);
      } else {
        expect(find.byType(ContactListsPage), findsNothing);
      }
      expect(find.text('All iPhone'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Desktop selects groups and searches contacts', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(const RolodexApp());
    await tester.pumpAndSettle();
    expect(find.text('51'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Daniel Higgins'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(ContactListsPage))).canPop(),
      isFalse,
    );
    expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(CupertinoSearchTextField)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'missing');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Không tìm thấy liên hệ.'), findsOneWidget);

    await tester.tap(find.text('All iPhone'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(CupertinoSearchTextField)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'JOHN');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('John Appleseed'), findsOneWidget);
    expect(find.text('Jennifer Adams'), findsNothing);
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(find.text('Nhóm này chưa có liên hệ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phone opens a group, scrolls contacts, and goes back', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(const RolodexApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('All iPhone'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactListsPage), findsOneWidget);
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    final route =
        ModalRoute.of(tester.element(find.byType(ContactListsPage)))!
            as CupertinoPageRoute<void>;
    expect(route.title, 'iPhone');
    await tester.scrollUntilVisible(
      find.text('Zachary Zimmerman'),
      400,
      scrollable: find
          .descendant(
            of: find.byType(ContactListsPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Zachary Zimmerman'), findsOneWidget);
    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();
    expect(find.text('All iPhone'), findsOneWidget);
    expect(find.byType(ContactListsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Supports swipe back and returning after a phone-to-desktop resize',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(390, 800));
      await tester.pumpWidget(const RolodexApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
      expect(find.text('Daniel Higgins'), findsOneWidget);

      await tester.dragFrom(const Offset(1, 400), const Offset(330, 0));
      await tester.pumpAndSettle();
      expect(find.byType(ContactListsPage), findsNothing);
      expect(find.text('All iPhone'), findsOneWidget);

      await tester.tap(find.text('All iPhone'));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CupertinoNavigationBarBackButton));
      await tester.pumpAndSettle();
      expect(find.text('All iPhone'), findsOneWidget);
      expect(find.byType(ContactListsPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(ContactListsPage))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
