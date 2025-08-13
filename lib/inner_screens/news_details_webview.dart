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
  const NewsDetailsWebView({Key? key, required this.url}) : super(key: key);
  final String url;

  @override
  State<NewsDetailsWebView> createState() => _NewsDetailsWebViewState();
}

class _NewsDetailsWebViewState extends State<NewsDetailsWebView> {
  late final WebViewController _controller;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // URL segura (http/https), si no lo es, se evita crash al parsear
    final Uri initialUri = Uri.tryParse(widget.url) ?? Uri();
    if (!initialUri.hasScheme || !(initialUri.isScheme('http') || initialUri.isScheme('https'))) {
      // Si viene algo raro, intenta forzar http
      _safeShowError('Invalid URL: ${widget.url}');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) => setState(() => _progress = progress / 100),
          onPageStarted: (_) => setState(() => _progress = 0),
          onPageFinished: (_) => setState(() => _progress = 1),
          onWebResourceError: (error) {
            log('WebView error: $error');
            _safeShowError(error.description);
          },
        ),
      )
      ..loadRequest(
        initialUri.hasScheme ? initialUri : Uri.parse('https://${widget.url}'),
      );
  }

  void _safeShowError(String message) {
    if (!mounted) return;
    GlobalMethods.errorDialog(errorMessage: message, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).getColor;
    final String titleHost = Uri.tryParse(widget.url)?.host.isNotEmpty == true
        ? Uri.parse(widget.url).host
        : 'Web';

    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // quedarse en la pantalla
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
          title: Text(titleHost, style: TextStyle(color: color), overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              onPressed: _showModalSheetFct,
              icon: const Icon(Icons.more_horiz),
              tooltip: 'Más opciones',
            ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            Expanded(
              child: WebViewWidget(controller: _controller),
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
              const Text('More options', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
              const VerticalSpacing(20),
              const Divider(thickness: 2),
              const VerticalSpacing(10),

              // Compartir
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () async {
                  try {
                    final currentUrl = await _controller.currentUrl();
                    await Share.share(
                      currentUrl ?? widget.url,
                      subject: 'Mira esta noticia',
                    );
                  } catch (err) {
                    _safeShowError(err.toString());
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),

              // Abrir en navegador externo
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in browser'),
                onTap: () async {
                  try {
                    final currentUrl = await _controller.currentUrl();
                    final uri = Uri.parse(currentUrl ?? widget.url);
                    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    if (!ok) {
                      _safeShowError('Could not launch $uri');
                    }
                  } catch (err) {
                    _safeShowError(err.toString());
                  } finally {
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),

              // Recargar
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () async {
                  try {
                    await _controller.reload();
                  } catch (err) {
                    log('Reload error: $err');
                  } finally {
                    if (mounted) Navigator.pop(context);
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
