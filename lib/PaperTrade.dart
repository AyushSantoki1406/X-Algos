import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class PaperTrade extends StatefulWidget {
  const PaperTrade({super.key});

  @override
  State<PaperTrade> createState() => _PaperTradeState();
}

class _PaperTradeState extends State<PaperTrade> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'PaperTrade',
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
        body: const PaperTradePage(),
      ),
    );
  }
}

class PaperTradePage extends StatelessWidget {
  const PaperTradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("PaperTrade Page Content Goes Here!"),
    );
  }
}
