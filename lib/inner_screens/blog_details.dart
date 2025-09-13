import 'package:app_news/providers/bookmarks_provider.dart';
import 'package:app_news/providers/news_provider.dart';
import 'package:app_news/services/global_methods.dart';
import 'package:app_news/widgets/vertical_spacing.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../consts/styles.dart';
import '../services/utils.dart';

class NewsDetailsScreen extends StatefulWidget {
  static const routeName = "/NewsDetailsScreen";
  const NewsDetailsScreen({super.key});

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  String _publishedAt = '';
  String? _bookmarkKey; // si vienes desde bookmarks
  bool _isFromBookmarks = false;
  bool _argsParsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsParsed) return;

    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is String) {
      _publishedAt = args;
    } else if (args is Map) {
      _publishedAt = (args['publishedAt'] ?? '').toString();
      _bookmarkKey = args['bookmarkKey'] as String?;
      _isFromBookmarks = (args['isBookmark'] as bool?) ?? false;
    }

    // precarga bookmarks si aún no están
    final bm = context.read<BookmarksProvider>();
    if (bm.bookmarkList.isEmpty) {
      bm.fetchBookmarks();
    }

    _argsParsed = true;
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).getColor;
    final newsProvider = context.watch<NewsProvider>();
    final bmWatch = context.watch<BookmarksProvider>();
    final bmRead = context.read<BookmarksProvider>();

    final currentNews = newsProvider.findByDate(publishedAt: _publishedAt);

    // ---- Identidad única de la noticia (usa URL primero) ----
    final String idForCheck = (currentNews.url.isNotEmpty)
        ? currentNews.url
        : (currentNews.newsId.isNotEmpty
              ? currentNews.newsId
              : '${currentNews.title}|${currentNews.publishedAt}');

    // Busca si ya existe en bookmarks por URL (o por newsId si URL vacía)
    String? existingKey;
    bool isBookmarked = false;
    for (final b in bmWatch.bookmarkList) {
      if (currentNews.url.isNotEmpty && b.url == currentNews.url) {
        existingKey = b.bookmarkKey;
        isBookmarked = true;
        break;
      }
      if (currentNews.url.isEmpty && b.newsId == idForCheck) {
        existingKey = b.bookmarkKey;
        isBookmarked = true;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: color),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          "By ${currentNews.authorName.isNotEmpty ? currentNews.authorName : 'Unknown'}",
          textAlign: TextAlign.center,
          style: TextStyle(color: color),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentNews.title,
                  textAlign: TextAlign.justify,
                  style: titleTextStyle,
                ),
                const VerticalSpacing(25),
                Row(
                  children: [
                    Text(currentNews.dateToShow, style: smallTextStyle),
                    const Spacer(),
                    Text(currentNews.readingTimeText, style: smallTextStyle),
                  ],
                ),
                const VerticalSpacing(20),
              ],
            ),
          ),
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: FancyShimmerImage(
                    boxFit: BoxFit.fill,
                    errorWidget: Image.asset('assets/images/empty_image.png'),
                    imageUrl: currentNews.urlToImage,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 10,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      // Compartir
                      GestureDetector(
                        onTap: () async {
                          try {
                            await Share.share(
                              currentNews.url,
                              subject: 'Check this article',
                            );
                          } catch (err) {
                            GlobalMethods.errorDialog(
                              errorMessage: err.toString(),
                              context: context,
                            );
                          }
                        },
                        child: Card(
                          elevation: 10,
                          shape: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              IconlyLight.send,
                              size: 28,
                              color: color,
                            ),
                          ),
                        ),
                      ),

                      // Bookmark: evita duplicar y elimina exactamente la correcta
                      GestureDetector(
                        onTap: () async {
                          try {
                            if (isBookmarked || _isFromBookmarks) {
                              final keyToDelete = _bookmarkKey ?? existingKey;
                              if (keyToDelete == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Esta noticia ya está en Bookmarks',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await bmRead.deleteBookmark(keyToDelete);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bookmark eliminado'),
                                ),
                              );
                            } else {
                              // Si tienes addToBookmarkIfNotExists, úsalo; previene duplicados
                              if (bmRead.bookmarkList.any(
                                (b) =>
                                    b.url == currentNews.url ||
                                    (currentNews.url.isEmpty &&
                                        b.newsId == idForCheck),
                              )) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Esta noticia ya está en Bookmarks',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await bmRead.addToBookmark(
                                newsModel: currentNews,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bookmark agregado'),
                                ),
                              );
                            }
                          } catch (err) {
                            if (!mounted) return;
                            GlobalMethods.errorDialog(
                              errorMessage: err.toString(),
                              context: context,
                            );
                          }
                        },
                        child: Card(
                          elevation: 10,
                          shape: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              (isBookmarked || _isFromBookmarks)
                                  ? IconlyBold.bookmark
                                  : IconlyLight.bookmark,
                              size: 28,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const VerticalSpacing(20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                TextContent(
                  label: 'Description',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                VerticalSpacing(10),
                // Los siguientes TextContent se llenan abajo:
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextContent(
                  label: currentNews.description,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
                const VerticalSpacing(20),
                const TextContent(
                  label: 'Contents',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                const VerticalSpacing(10),
                TextContent(
                  label: currentNews.content,
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextContent extends StatelessWidget {
  const TextContent({
    super.key,
    required this.label,
    required this.fontSize,
    required this.fontWeight,
  });

  final String label;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      label,
      textAlign: TextAlign.justify,
      style: GoogleFonts.roboto(fontSize: fontSize, fontWeight: fontWeight),
    );
  }
}
