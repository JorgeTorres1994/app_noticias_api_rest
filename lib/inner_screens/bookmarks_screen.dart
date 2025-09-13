import 'package:app_news/consts/vars.dart';
import 'package:app_news/providers/bookmarks_provider.dart';
import 'package:app_news/services/utils.dart';
import 'package:app_news/widgets/articles_widget.dart';
import 'package:app_news/widgets/drawer_widget.dart';
import 'package:app_news/widgets/empty_screen.dart';
import 'package:app_news/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = Utils(context).getScreenSize;
    final Color color = Utils(context).getColor;
    return Scaffold(
      drawer: DrawerWidget(),
      appBar: AppBar(
        iconTheme: IconThemeData(color: color),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          'Bookmarks',
          style: GoogleFonts.lobster(
            textStyle: TextStyle(
              color: color,
              fontSize: 20,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<void>(
            future: Provider.of<BookmarksProvider>(
              context,
              listen: false,
            ).fetchBookmarks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: LoadingWidget(newsType: NewsType.allNews),
                );
              }
              if (snapshot.hasError) {
                return Expanded(
                  child: EmptyNewsWidget(
                    text: "an error occured ${snapshot.error}",
                    imagePath: 'assets/images/no_news.png',
                  ),
                );
              }

              // Leer la data desde el provider
              final items = context.watch<BookmarksProvider>().bookmarkList;
              if (items.isEmpty) {
                return const Expanded(
                  child: EmptyNewsWidget(
                    text: "You didn't add anything yet to your bookmarks",
                    imagePath: "assets/images/bookmark.png",
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final bm = items[index];
                    return ChangeNotifierProvider.value(
                      value: bm,
                      child: const ArticlesWidget(isBookmark: true),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
