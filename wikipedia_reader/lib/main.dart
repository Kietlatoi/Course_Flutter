import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'summary.dart';

void main() {
  runApp(const MainApp());
}

class ArticleModel {
  Future<Summary> getRandomArticleSummary() async {
    final uri = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/random/summary',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw const HttpException('Failed to update resource');
    }

    return Summary.fromJson(jsonDecode(response.body) as Map<String, Object?>);
  }
}

class ArticleViewModel extends ChangeNotifier {
  ArticleViewModel(this.model) {
    fetchArticle();
  }

  final ArticleModel model;
  Summary? summary;
  Exception? error;
  bool isLoading = false;
  bool _disposed = false;

  Future<void> fetchArticle() async {
    if (_disposed || isLoading) return;

    isLoading = true;
    notifyListeners();
    try {
      summary = await model.getRandomArticleSummary();
      error = null;
      debugPrint('Article loaded: ${summary!.titles.normalized}');
    } on Exception catch (e) {
      error = e;
      summary = null;
      debugPrint('Error loading article: $e');
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ArticleView());
  }
}

class ArticleView extends StatefulWidget {
  const ArticleView({super.key});

  @override
  State<ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<ArticleView> {
  late final ArticleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ArticleViewModel(ArticleModel());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wikipedia Flutter')),
      body: Center(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return switch ((
              _viewModel.isLoading,
              _viewModel.summary,
              _viewModel.error,
            )) {
              (true, _, _) => const CircularProgressIndicator(),
              (_, _, final Exception _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải bài viết. Vui lòng thử lại.'),
                  ElevatedButton(
                    onPressed: _viewModel.fetchArticle,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
              (_, final summary?, _) => ArticlePage(
                summary: summary,
                nextArticleCallback: _viewModel.fetchArticle,
              ),
              _ => const Text('Chưa có bài viết để hiển thị.'),
            };
          },
        ),
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({
    super.key,
    required this.summary,
    required this.nextArticleCallback,
  });

  final Summary summary;
  final VoidCallback nextArticleCallback;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ArticleWidget(summary: summary),
          ElevatedButton(
            onPressed: nextArticleCallback,
            child: const Text('Next random article'),
          ),
        ],
      ),
    );
  }
}

class ArticleWidget extends StatelessWidget {
  const ArticleWidget({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        spacing: 10,
        children: [
          if (summary.hasImage)
            Image.network(
              summary.originalImage!.source,
              semanticLabel: summary.titles.normalized,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('Không tải được ảnh'),
            ),
          Text(
            summary.titles.normalized,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          if (summary.description != null)
            Text(
              summary.description!,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(summary.extract),
        ],
      ),
    );
  }
}
