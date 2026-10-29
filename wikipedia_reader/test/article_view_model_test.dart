import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wikipedia_reader/main.dart';
import 'package:wikipedia_reader/summary.dart';

class FakeArticleModel extends ArticleModel {
  FakeArticleModel(this.load);

  final Future<Summary> Function() load;

  @override
  Future<Summary> getRandomArticleSummary() => load();
}

void main() {
  final summary = Summary(
    titles: TitlesSet(
      canonical: 'Flutter',
      normalized: 'Flutter',
      display: 'Flutter',
    ),
    pageId: 1,
    extract: 'A UI toolkit.',
    extractHtml: '<p>A UI toolkit.</p>',
    lang: 'en',
    dir: 'ltr',
    url: 'https://en.wikipedia.org/wiki/Flutter',
  );

  test(
    'Loads automatically, notifies listeners, and avoids duplicate requests',
    () async {
      var calls = 0;
      var pending = Completer<Summary>();
      final viewModel = ArticleViewModel(
        FakeArticleModel(() {
          calls++;
          return pending.future;
        }),
      );
      addTearDown(viewModel.dispose);
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.summary, isNull);
      await viewModel.fetchArticle();
      expect(calls, 1);
      pending.complete(summary);
      await pumpEventQueue();
      expect(viewModel.summary, same(summary));
      expect(viewModel.error, isNull);
      expect(loadingStates, [false]);

      pending = Completer<Summary>();
      final refresh = viewModel.fetchArticle();
      expect(loadingStates, [false, true]);
      pending.complete(summary);
      await refresh;
      expect(calls, 2);
      expect(loadingStates, [false, true, false]);
    },
  );

  for (final failure in <Exception>[
    const HttpException('Service unavailable'),
    http.ClientException('Offline'),
    const FormatException('Invalid JSON'),
  ]) {
    test('Stores ${failure.runtimeType} and recovers on retry', () async {
      var pending = Completer<Summary>();
      final viewModel = ArticleViewModel(
        FakeArticleModel(() => pending.future),
      );
      addTearDown(viewModel.dispose);
      pending.complete(summary);
      await pumpEventQueue();

      pending = Completer<Summary>();
      final failedRequest = viewModel.fetchArticle();
      pending.completeError(failure);
      await failedRequest;
      expect(viewModel.error, same(failure));
      expect(viewModel.summary, isNull);
      expect(viewModel.isLoading, isFalse);

      pending = Completer<Summary>();
      final retry = viewModel.fetchArticle();
      pending.complete(summary);
      await retry;
      expect(viewModel.error, isNull);
      expect(viewModel.summary, same(summary));
      expect(viewModel.isLoading, isFalse);
    });
  }

  test('Does not notify after disposal during a request', () async {
    final pending = Completer<Summary>();
    final viewModel = ArticleViewModel(FakeArticleModel(() => pending.future));
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    viewModel.dispose();
    pending.complete(summary);
    await pumpEventQueue();
    expect(notifications, 0);
  });
}
