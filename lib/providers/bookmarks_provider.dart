import 'dart:convert';

import 'package:app_news/models/bookmarks_model.dart';
import 'package:app_news/models/news_model.dart';
import 'package:app_news/services/news_api.dart';
import 'package:flutter/cupertino.dart';

import '../consts/api_consts.dart';

import 'package:http/http.dart' as http;

class BookmarksProvider with ChangeNotifier {
  List<BookmarksModel> _bookmarkList = [];
  List<BookmarksModel> get bookmarkList => _bookmarkList;

  /*Future<void> fetchBookmarks() async {
    final list = await NewsAPiServices.getBookmarks();
    _bookmarkList = list;
    notifyListeners();
  }

  Future<void> addToBookmark({required NewsModel newsModel}) async {
    try {
      final uri = Uri.https(BASEURL_FIREBASE, 'bookmarks.json');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newsModel.toJson()),
      );
      if (res.statusCode == 200) {
        await fetchBookmarks();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBookmark(String idFirebase) async {
    try {
      final uri = Uri.https(BASEURL_FIREBASE, 'bookmarks/$idFirebase.json');
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        _bookmarkList.removeWhere((b) => b.bookmarkKey == idFirebase);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }*/

  Future<void> addToBookmark({required NewsModel newsModel}) async {
    try {
      final uri = Uri.https(BASEURL_FIREBASE, 'bookmarks.json');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newsModel.toJson()),
      );
      if (res.statusCode == 200) {
        await fetchBookmarks();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchBookmarks() async {
    final list = await NewsAPiServices.getBookmarks();
    _bookmarkList = list;
    notifyListeners();
  }

  // --- NUEVO: helpers de duplicados ---
  bool isBookmarkedById(String newsId) {
    return _bookmarkList.any((b) => b.newsId == newsId);
  }

  String? findKeyByNewsId(String newsId) {
    final idx = _bookmarkList.indexWhere((b) => b.newsId == newsId);
    if (idx == -1) return null;
    return _bookmarkList[idx].bookmarkKey;
  }

  /// Intenta agregar; retorna true si agregó, false si ya existía
  Future<bool> addToBookmarkIfNotExists({required NewsModel newsModel}) async {
    // si no está cargada aún, carga una vez
    if (_bookmarkList.isEmpty) {
      await fetchBookmarks();
    }
    final exists = _bookmarkList.any((b) => b.newsId == newsModel.newsId);
    if (exists) return false;

    final uri = Uri.https(BASEURL_FIREBASE, 'bookmarks.json');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newsModel.toJson()),
    );

    if (res.statusCode == 200) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final key = map['name'] as String?;
      if (key != null) {
        _bookmarkList.insert(
          0,
          BookmarksModel.fromJson(json: newsModel.toJson(), bookmarkKey: key),
        );
        notifyListeners();
      } else {
        await fetchBookmarks(); // fallback
      }
      return true;
    }
    throw Exception('rtdb_http_${res.statusCode}');
  }

  // Mantén tu delete por key
  Future<void> deleteBookmark(String idFirebase) async {
    final uri = Uri.https(BASEURL_FIREBASE, 'bookmarks/$idFirebase.json');
    final res = await http.delete(uri);
    if (res.statusCode == 200) {
      _bookmarkList.removeWhere((b) => b.bookmarkKey == idFirebase);
      notifyListeners();
    } else {
      throw Exception('rtdb_http_${res.statusCode}');
    }
  }
}
