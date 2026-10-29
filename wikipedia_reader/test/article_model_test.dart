import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wikipedia_reader/main.dart';

void main() {
  test('Requests a random summary and parses the response', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://en.wikipedia.org/api/rest_v1/page/random/summary',
      );
      return http.Response(
        jsonEncode({
          'titles': {
            'canonical': 'Flutter',
            'normalized': 'Flutter',
            'display': 'Flutter',
          },
          'pageid': 1,
          'extract': 'A UI toolkit.',
          'extract_html': '<p>A UI toolkit.</p>',
          'lang': 'en',
          'dir': 'ltr',
          'content_urls': {
            'desktop': {'page': 'https://en.wikipedia.org/wiki/Flutter'},
            'mobile': {'page': 'https://en.m.wikipedia.org/wiki/Flutter'},
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final summary = await http.runWithClient(
      () => ArticleModel().getRandomArticleSummary(),
      () => client,
    );
    expect(summary.titles.display, 'Flutter');
    expect(summary.pageId, 1);
    expect(summary.extract, 'A UI toolkit.');
  });

  test('Rejects unsuccessful HTTP responses before decoding JSON', () async {
    final client = MockClient(
      (_) async => http.Response('Service unavailable', 503),
    );
    await expectLater(
      http.runWithClient(
        () => ArticleModel().getRandomArticleSummary(),
        () => client,
      ),
      throwsA(isA<HttpException>()),
    );
  });

  for (final body in ['not JSON', '{}']) {
    test('Rejects invalid response data: $body', () async {
      final client = MockClient((_) async => http.Response(body, 200));
      await expectLater(
        http.runWithClient(
          () => ArticleModel().getRandomArticleSummary(),
          () => client,
        ),
        throwsFormatException,
      );
    });
  }

  test('Propagates network failures to the caller', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    await expectLater(
      http.runWithClient(
        () => ArticleModel().getRandomArticleSummary(),
        () => client,
      ),
      throwsA(isA<http.ClientException>()),
    );
  });
}
