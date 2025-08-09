import 'dart:developer';
import 'package:app_news/widgets/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/utils.dart';

class NewsDetailsWebView extends StatefulWidget {
  const NewsDetailsWebView({Key? key}) : super(key: key);

  @override
  State<NewsDetailsWebView> createState() => _NewsDetailsWebViewState();
}

class _NewsDetailsWebViewState extends State<NewsDetailsWebView> {
  late final WebViewController _webViewController;
  double _progress = 0.0;

  final String url =
      "https://techcrunch.com/2022/06/17/marc-lores-food-delivery-startup-wonder-raises-350m-3-5b-valuation/";

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).getColor;
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(IconlyLight.arrowLeft2),
            onPressed: () => Navigator.pop(context),
          ),
          iconTheme: IconThemeData(color: color),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text("URL", style: TextStyle(color: color)),
          actions: [
            IconButton(
              onPressed: () async => _showModalSheetFct(),
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: _progress,
              color: _progress == 1.0 ? Colors.transparent : Colors.blue,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            Expanded(
              child: WebViewWidget(controller: _webViewController),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showModalSheetFct() async {
    await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VerticalSpacing(20),
              Center(
                child: Container(
                  height: 5,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const VerticalSpacing(20),
              const Text(
                'More option',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              const VerticalSpacing(20),
              const Divider(thickness: 2),
              const VerticalSpacing(20),

              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () async {
                  try {
                    String? current = await _webViewController.currentUrl();
                    final toShare = current?.isNotEmpty == true ? current! : url;
                    await Share.share(toShare, subject: 'Check out this article!');
                  } catch (err) {
                    log(err.toString());
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in browser'),
                onTap: () async {
                  try {
                    final uri = Uri.parse(url);
                    final ok = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok) throw 'Could not launch $uri';
                  } catch (err) {
                    log(err.toString());
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () async {
                  try {
                    await _webViewController.reload();
                  } catch (err) {
                    log("error occured $err");
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
