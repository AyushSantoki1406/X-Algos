import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class LiveTrade extends StatefulWidget {
  const LiveTrade({super.key});

  @override
  State<LiveTrade> createState() => _LiveTradeState();
}

class _LiveTradeState extends State<LiveTrade> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'LiveTrade',
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
      body: const LiveTradePage(),
    );
  }
}

class LiveTradePage extends StatelessWidget {
  const LiveTradePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("LiveTrade Page Content Goes Here!"),
    );
  }
}
