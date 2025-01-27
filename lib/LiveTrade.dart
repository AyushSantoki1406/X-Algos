import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveTradePage extends StatefulWidget {
  const LiveTradePage({super.key});

  @override
  State<LiveTradePage> createState() => _LiveTradePageState();
}

class _LiveTradePageState extends State<LiveTradePage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController with JavaScript enabled
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(
          Colors.transparent) // Optional: to avoid white flickers
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div id="tradingview_12345"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
              <script type="text/javascript">
                new TradingView.widget({
                  "width": "100%",
                  "height": 500,
                  "symbol": "BTCUSD",
                  "interval": "D",
                  "timezone": "Etc/UTC",
                  "theme": "dark",
                  "style": "1",
                  "locale": "en",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "hide_top_toolbar": true,
                  "allow_symbol_change": true,
                  "container_id": "tradingview_12345"
                });
              </script>
            </div>
          </body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Trade'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
