import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class Subcribed extends StatefulWidget {
  const Subcribed({super.key});

  @override
  State<Subcribed> createState() => _SubcribedState();
}

class _SubcribedState extends State<Subcribed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Subcribed',
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
      body: const SubcribedPage(),
    );
  }
}

class SubcribedPage extends StatelessWidget {
  const SubcribedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min size for smaller column
        children: [
          Row(
            children: [
              // First child takes half the width
              Expanded(
                child: Container(
                  height: 100, // Set height for the container
                  color: Colors.blue,
                  child: const Center(
                    child: Text(
                      'Child 1',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              // Second child takes half the width
              Expanded(
                child: Container(
                  height: 100, // Set height for the container
                  color: Colors.green,
                  child: const Center(
                    child: Text(
                      'Child 2',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
