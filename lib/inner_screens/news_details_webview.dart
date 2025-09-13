import 'dart:developer';

import 'package:app_news/widgets/vertical_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/global_methods.dart';
import '../services/utils.dart';

class NewsDetailsWebView extends StatefulWidget {
  const NewsDetailsWebView({super.key, required this.url});
  final String url;

  @override
  State<NewsDetailsWebView> createState() => _NewsDetailsWebViewState();
}

class _NewsDetailsWebViewState extends State<NewsDetailsWebView> {
  late final WebViewController _webViewController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() => _progress = progress / 100.0);
          },
          onWebResourceError: (error) {
            log('WebView error: $error');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).getColor;

    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          // permanecer dentro del WebView
          return false;
        }
        return true;
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
          title: Text(
            widget.url,
            style: TextStyle(color: color),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              onPressed: _showModalSheetFct,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: Column(
          children: [
            // Muestra progreso de carga (0->1). Cuando termina, lo “ocultamos”
            LinearProgressIndicator(
              value: _progress < 1.0 ? _progress : null,
              color: _progress == 1.0 ? Colors.transparent : Colors.blue,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            Expanded(child: WebViewWidget(controller: _webViewController)),
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
                'More options',
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
                    await Share.share(widget.url, subject: 'Look what I made!');
                  } catch (err) {
                    GlobalMethods.errorDialog(
                      errorMessage: err.toString(),
                      context: context,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in browser'),
                onTap: () async {
                  final uri = Uri.parse(widget.url);
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok) {
                    GlobalMethods.errorDialog(
                      errorMessage: 'Could not launch ${uri.toString()}',
                      context: context,
                    );
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
                    log('Reload error: $err');
                  } finally {
                    Navigator.pop(context);
                  }
                },
              ),
              const VerticalSpacing(10),
            ],
          ),
        );
      },
    );
  }
}
