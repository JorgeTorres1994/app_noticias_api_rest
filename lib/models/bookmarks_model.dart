import 'package:flutter/foundation.dart';

class BookmarksModel with ChangeNotifier {
  final String bookmarkKey;
  final String newsId;
  final String sourceName;
  final String authorName;
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;
  final String dateToShow;
  final String content;
  final String readingTimeText;

  BookmarksModel({
    required this.bookmarkKey,
    required this.newsId,
    required this.sourceName,
    required this.authorName,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
    required this.dateToShow,
    required this.readingTimeText,
  });

  /// Crea un BookmarksModel desde el valor guardado en RTDB para una key-.
  factory BookmarksModel.fromJson({
    required Map<String, dynamic>? json,
    required String bookmarkKey,
  }) {
    final map = json ?? const <String, dynamic>{};

    return BookmarksModel(
      bookmarkKey: bookmarkKey,
      newsId: (map['newsId'] ?? '').toString(),
      sourceName: (map['sourceName'] ?? '').toString(),
      authorName: (map['authorName'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      urlToImage:
          (map['urlToImage'] ??
                  'https://cdn-icons-png.flaticon.com/512/833/833268.png')
              .toString(),
      publishedAt: (map['publishedAt'] ?? '').toString(),
      dateToShow: (map['dateToShow'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      readingTimeText: (map['readingTimeText'] ?? '').toString(),
    );
  }

  /// Convierte a JSON para guardar en RTDB (útil al hacer POST).
  Map<String, dynamic> toJson() => {
    'newsId': newsId,
    'sourceName': sourceName,
    'authorName': authorName,
    'title': title,
    'description': description,
    'url': url,
    'urlToImage': urlToImage,
    'publishedAt': publishedAt,
    'dateToShow': dateToShow,
    'content': content,
    'readingTimeText': readingTimeText,
  };

  /// Construye la lista de bookmarks a partir del objeto raíz (mapa)
  /// y las keys generadas por Firebase. Ignora hijos nulos o no-mapa.
  static List<BookmarksModel> bookmarksFromSnapshot({
    required Map<String, dynamic> json,
    required List<String> allKeys,
  }) {
    final out = <BookmarksModel>[];
    for (final key in allKeys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        out.add(BookmarksModel.fromJson(json: value, bookmarkKey: key));
      } else if (value is Map) {
        out.add(
          BookmarksModel.fromJson(
            json: value.cast<String, dynamic>(),
            bookmarkKey: key,
          ),
        );
      }
      // Si value es null u otro tipo, lo ignoramos silenciosamente
    }
    return out;
  }

  @override
  String toString() {
    return 'Bookmark($bookmarkKey) {newsId: $newsId, sourceName: $sourceName, authorName: $authorName, title: $title, url: $url}';
  }
}
