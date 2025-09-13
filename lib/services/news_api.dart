import 'dart:convert';
import 'dart:developer';

import 'package:app_news/models/bookmarks_model.dart';
import 'package:app_news/models/news_model.dart';
import 'package:http/http.dart' as http;

import '../consts/api_consts.dart';
import '../consts/http_exception.dart';

class NewsAPiServices {
  static Future<List<NewsModel>> getAllNews({
    required int page,
    required String sortBy, // relevancy | popularity | publishedAt
  }) async {
    try {
      // Usa EVERYTHING para soportar sortBy + pagination
      final uri = Uri.https(BASEURL, 'v2/everything', {
        'q': 'technology', // puedes cambiarlo por el tema que prefieras
        'language': 'en',
        'page': '$page', // <- paginación
        'pageSize': '20', // <- ítems por página
        'sortBy': sortBy, // <- usa el dropdown
      });

      final res = await http.get(uri, headers: {'X-Api-Key': API_KEY});
      if (res.statusCode != 200) {
        throw HttpException('newsapi_http_${res.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(res.body);
      if (data['status'] == 'error') {
        throw HttpException(data['code'] ?? 'newsapi_error');
      }

      final List articles = (data['articles'] as List? ?? []);
      return NewsModel.newsFromSnapshot(articles);
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<List<NewsModel>> getTopHeadlines() async {
    try {
      var uri = Uri.https(BASEURL, "v2/top-headlines", {'country': 'us'});
      var response = await http.get(uri, headers: {"X-Api-key": API_KEY});
      log('Response status: ${response.statusCode}');
      // log('Response body: ${response.body}');
      Map data = jsonDecode(response.body);
      List newsTempList = [];

      if (data['code'] != null) {
        throw HttpException(data['code']);
        // throw data['message'];
      }
      for (var v in data["articles"]) {
        newsTempList.add(v);
        // log(v.toString());
        // print(data["articles"].length.toString());
      }
      return NewsModel.newsFromSnapshot(newsTempList);
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<List<NewsModel>> searchNews({required String query}) async {
    try {
      var uri = Uri.https(BASEURL, "v2/everything", {
        "q": query,
        "pageSize": "10",
        "domains": "techcrunch.com",
      });
      var response = await http.get(uri, headers: {"X-Api-key": API_KEY});
      // log('Response status: ${response.statusCode}');
      // log('Response body: ${response.body}');
      Map data = jsonDecode(response.body);
      List newsTempList = [];

      if (data['code'] != null) {
        throw HttpException(data['code']);
        // throw data['message'];
      }
      for (var v in data["articles"]) {
        newsTempList.add(v);
        // log(v.toString());
        // print(data["articles"].length.toString());
      }
      return NewsModel.newsFromSnapshot(newsTempList);
    } catch (error) {
      throw error.toString();
    }
  }

  /*static Future<List<BookmarksModel>?> getBookmarks() async {
    try {
      var uri = Uri.https(BASEURL_FIREBASE, "bookmarks.json");
      var response = await http.get(uri);
      // log('Response status: ${response.statusCode}');
      // log('Response body: ${response.body}');

      Map data = jsonDecode(response.body);
      List allKeys = [];

      if(data['code']!= null) {
        throw HttpException(data['code']);
        // throw data['message'];
      }
      for(String key in data.keys) {
        allKeys.add(key);

      }
      return BookmarksModel.bookmarksFromSnapshot(json: data, allKeys: allKeys);
    } catch (error) {
      rethrow;
    }
  }*/

  // dentro de class NewsAPiServices
  // services/news_api.dart
  static Future<List<BookmarksModel>> getBookmarks({
    String path = 'bookmarks',
  }) async {
    try {
      final uri = Uri.https(BASEURL_FIREBASE, '$path.json');
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        throw HttpException('rtdb_http_${res.statusCode}');
      }

      final body = res.body.trim();
      if (body.isEmpty || body == 'null') {
        return <BookmarksModel>[];
      }

      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;

      // 🔴 hay hijos que pueden venir null; filtrémoslos
      final Map<String, dynamic> cleaned = {};
      data.forEach((k, v) {
        if (v is Map) cleaned[k] = v.cast<String, dynamic>();
      });

      if (cleaned.isEmpty) return <BookmarksModel>[];

      final keys = cleaned.keys.toList(growable: false);
      return BookmarksModel.bookmarksFromSnapshot(json: cleaned, allKeys: keys);
    } catch (e) {
      rethrow;
    }
  }
}
