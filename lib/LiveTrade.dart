import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiveTradePage extends StatefulWidget {
  const LiveTradePage({super.key});

  @override
  State<LiveTradePage> createState() => _LiveTradePageState();
}

class _LiveTradePageState extends State<LiveTradePage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    // Initialize WebViewController with JavaScript enabled
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(Colors.transparent) // To avoid white flickers
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <script src="https://unpkg.com/lightweight-charts/dist/lightweight-charts.standalone.production.js"></script>
          </head>
          <body>
            <div id="chart" style="width: 100%; height: 500px;"></div>
            <script>
              const chart = LightweightCharts.createChart(document.getElementById('chart'), {
                layout: {
                  backgroundColor: '#000000',
                  textColor: '#d1d4dc',
                },
                grid: {
                  vertLines: { color: '#333' },
                  horzLines: { color: '#333' },
                },
                width: 300,
                height: 500,
              });
              const lineSeries = chart.addLineSeries();
              lineSeries.setData([
                { time: '2023-01-01', value: 102 },
                { time: '2023-02-01', value: 108 },
                { time: '2023-03-01', value: 115 },
              ]);
            </script>
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
