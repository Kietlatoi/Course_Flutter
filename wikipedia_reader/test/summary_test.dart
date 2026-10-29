import 'package:flutter_test/flutter_test.dart';
import 'package:wikipedia_reader/summary.dart';

void main() {
  final json = <String, Object?>{
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
  };

  test('Parses an article without optional images or description', () {
    final summary = Summary.fromJson(json);
    expect(summary.titles.display, 'Flutter');
    expect(summary.extract, 'A UI toolkit.');
    expect(summary.hasImage, isFalse);
    expect(summary.description, isNull);
  });

  test('Parses an article with images and description', () {
    final image = <String, Object?>{
      'source': 'https://example.com/flutter.png',
      'width': 100,
      'height': 100,
    };
    final summary = Summary.fromJson({
      ...json,
      'description': 'UI toolkit',
      'thumbnail': image,
      'originalimage': image,
    });
    expect(summary.hasImage, isTrue);
    expect(summary.thumbnail!.toJson(), image);
    expect(summary.originalImage!.extension, 'png');
  });

  test('Rejects malformed summary data', () {
    expect(() => Summary.fromJson({}), throwsFormatException);
  });
}
