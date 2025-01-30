import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class ExecutedTrade extends StatefulWidget {
  const ExecutedTrade({super.key});

  @override
  State<ExecutedTrade> createState() => _ExecutedTradeState();
}

class _ExecutedTradeState extends State<ExecutedTrade> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'ExecutedTrade',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50), // Circular placeholder
              child: Image.asset(
                'assets/images/darklogo.png', // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          ],
        ),
        drawer: AppDrawer(), // Optional: left drawer
        endDrawer: AppDrawer(), // Right drawer (End drawer)
        body: const ExecutedTradePage(),
      ),
    );
  }
}

class ExecutedTradePage extends StatelessWidget {
  const ExecutedTradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("ExecutedTrade Page Content Goes Here!"),
    );
  }
}
