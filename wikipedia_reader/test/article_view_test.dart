import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wikipedia_reader/main.dart';
import 'package:wikipedia_reader/summary.dart';

http.Response articleResponse(String title) => http.Response(
  jsonEncode({
    'titles': {'canonical': title, 'normalized': title, 'display': title},
    'pageid': 1,
    'extract': 'An article about $title.',
    'extract_html': '<p>An article about $title.</p>',
    'description': 'Article description',
    'lang': 'en',
    'dir': 'ltr',
    'content_urls': {
      'desktop': {'page': 'https://en.wikipedia.org/wiki/$title'},
      'mobile': {'page': 'https://en.m.wikipedia.org/wiki/$title'},
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  testWidgets('Loads an article and refreshes it from the button', (
    tester,
  ) async {
    var pending = Completer<http.Response>();
    var requests = 0;
    final client = MockClient((_) {
      requests++;
      return pending.future;
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(const MainApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(articleResponse('Flutter'));
      await tester.pumpAndSettle();
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Article description'), findsOneWidget);
      expect(find.text('An article about Flutter.'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      tester.element(find.byType(ArticleView)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(requests, 1);

      pending = Completer<http.Response>();
      await tester.tap(find.text('Next random article'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(articleResponse('Dart'));
      await tester.pumpAndSettle();
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Flutter'), findsNothing);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets('Shows an error and retries successfully', (tester) async {
    var requests = 0;
    final client = MockClient(
      (_) async => ++requests == 1
          ? http.Response('Unavailable', 503)
          : articleResponse('Recovered'),
    );
    await http.runWithClient(() async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể tải bài viết. Vui lòng thử lại.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered'), findsOneWidget);
      expect(requests, 2);
      expect(tester.takeException(), isNull);
    }, () => client);
  });

  testWidgets('Keeps article text readable when its image fails', (
    tester,
  ) async {
    final summary = Summary(
      titles: TitlesSet(
        canonical: 'Image',
        normalized: 'Image',
        display: 'Image',
      ),
      pageId: 1,
      extract: 'Readable article text.',
      extractHtml: '<p>Readable article text.</p>',
      lang: 'en',
      dir: 'ltr',
      url: 'https://en.wikipedia.org/wiki/Image',
      thumbnail: ImageFile(
        source: 'https://example.com/missing.png',
        width: 100,
        height: 100,
      ),
      originalImage: ImageFile(
        source: 'https://example.com/missing.png',
        width: 100,
        height: 100,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ArticleWidget(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Readable article text.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Không tải được ảnh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
