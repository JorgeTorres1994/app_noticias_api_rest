import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_news/models/news_model.dart';
import 'package:http/http.dart' as http;

import '../consts/api_consts.dart';

class NewsAPiServices {
  static Future<List<NewsModel>> getAllNews() async {
    try {
      var uri = Uri.https(BASEURL, "v2/everything", {
        "q": "bitcoin",
        "pageSize": "5",
        "domains": "techcrunch.com",
      });
      var response = await http.get(uri, headers: {"X-Api-key": API_KEY});

      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');

      Map data = jsonDecode(response.body);
      List newsTempList = [];

      if (data['code'] != null) {
        throw HttpException(data['code']);
        //throw data['message'];
      }

      for (var v in data["articles"]) {
        newsTempList.add(v);
      }
      List<NewsModel> newsList = NewsModel.newsFromSnapshot(newsTempList);
      newsList = NewsModel.removeDuplicates(
        newsList,
      ); // Filtra duplicados por url
      return newsList;
    } catch (error) {
      throw error.toString();
    }
  }
}
