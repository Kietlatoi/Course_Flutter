import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wikipedia_reader/main.dart';

void main() {
  testWidgets('Loads once and displays a recoverable error', (tester) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('Service unavailable', 503);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();
      expect(find.text('Wikipedia Flutter'), findsOneWidget);
      expect(
        find.text('Không thể tải bài viết. Vui lòng thử lại.'),
        findsOneWidget,
      );
      tester.element(find.byType(MainApp)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
