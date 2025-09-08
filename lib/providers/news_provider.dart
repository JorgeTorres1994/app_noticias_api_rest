import 'package:app_news/models/news_model.dart';
import 'package:app_news/services/news_api.dart';
import 'package:flutter/cupertino.dart';

class NewsProvider with ChangeNotifier {
  List<NewsModel> newList = [];

  List<NewsModel> get getNewsList {
    return newList;
  }

  Future<List<NewsModel>> fetchAllNews(
      {required int pageIndex, required String sortBy}) async {
    newList = await NewsAPiServices.getAllNews(page: pageIndex, sortBy: sortBy);
    return newList;
  }

  Future<List<NewsModel>> fetchTopHeadlines() async {
    newList = await NewsAPiServices.getTopHeadlines();
    return newList;
  }

  Future<List<NewsModel>> searchNewsProvider({required String query}) async {
    newList = await NewsAPiServices.searchNews( query: query);
    return newList;
  }

  NewsModel findByDate({required String publishedAt}) {
    return newList.firstWhere((newsModel) => newsModel.publishedAt == publishedAt);
  }
}
