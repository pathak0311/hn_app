import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HackerNewsWebPage extends StatelessWidget {
  final String url;

  const HackerNewsWebPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Page')),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
