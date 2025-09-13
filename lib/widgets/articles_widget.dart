import 'package:app_news/inner_screens/news_details_webview.dart';
import 'package:app_news/models/bookmarks_model.dart';
import 'package:app_news/models/news_model.dart';
import 'package:app_news/services/utils.dart';
import 'package:app_news/widgets/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '../consts/styles.dart';
import '../inner_screens/blog_details.dart';

class ArticlesWidget extends StatelessWidget {
  const ArticlesWidget({super.key, this.isBookmark = false});
  final bool isBookmark;

  @override
  Widget build(BuildContext context) {
    final size = Utils(context).getScreenSize;

    // Puede venir BookmarksModel o NewsModel; ambos exponen los mismos getters en tu app
    final dynamic newsModelProvider = isBookmark
        ? Provider.of<BookmarksModel>(context)
        : Provider.of<NewsModel>(context);

    // --- HERO TAG SEGURO Y ÚNICO ---
    // Evita duplicados usando una combinación estable de campos.
    final String pAt = (newsModelProvider.publishedAt ?? '').toString();
    final String url = (newsModelProvider.url ?? '').toString();
    final String title = (newsModelProvider.title ?? '').toString();

    // Si todo viniera vacío, aún así creamos algo único con los hashes.
    final String heroTag = 'hero_${pAt}_${url.hashCode}_${title.hashCode}';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Theme.of(context).cardColor,
        child: GestureDetector(
          onTap: () {
            if (isBookmark) {
              // newsModelProvider es BookmarksModel
              Navigator.pushNamed(
                context,
                NewsDetailsScreen.routeName,
                arguments: {
                  'publishedAt': (newsModelProvider.publishedAt ?? '')
                      .toString(),
                  'bookmarkKey': (newsModelProvider.bookmarkKey ?? '')
                      .toString(),
                  'isBookmark': true,
                },
              );
            } else {
              // feed normal: conserva comportamiento anterior
              Navigator.pushNamed(
                context,
                NewsDetailsScreen.routeName,
                arguments: (newsModelProvider.publishedAt ?? '').toString(),
              );
            }
          },
          child: Stack(
            children: [
              Container(
                height: 60,
                width: 60,
                color: Theme.of(context).colorScheme.secondary,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 60,
                  width: 60,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Hero(
                        tag: heroTag, // <<--- TAG ÚNICO
                        child: FancyShimmerImage(
                          height: size.height * 0.12,
                          width: size.height * 0.12,
                          boxFit: BoxFit.fill,
                          errorWidget: Image.asset(
                            'assets/images/empty_image.png',
                          ),
                          imageUrl: (newsModelProvider.urlToImage ?? '')
                              .toString(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.justify,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: smallTextStyle,
                          ),
                          const VerticalSpacing(5),
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              '🕒 ${(newsModelProvider.readingTimeText ?? '').toString()}',
                              style: smallTextStyle,
                            ),
                          ),
                          FittedBox(
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.rightToLeft,
                                        child: NewsDetailsWebView(
                                          url: (newsModelProvider.url ?? '')
                                              .toString(),
                                        ),
                                        inheritTheme: true,
                                        ctx: context,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.link,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  (newsModelProvider.dateToShow ?? '')
                                      .toString(),
                                  maxLines: 1,
                                  style: smallTextStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
