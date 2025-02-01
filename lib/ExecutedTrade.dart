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
    return WillPopScope(
      onWillPop: () async => false, // Prevents back button navigation
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('ExecutedTrade'),
        ),
        body: const Center(
          child: Text("ExecutedTrade Page Content   Here!"),
        ),
      ),
    );
  }
}
