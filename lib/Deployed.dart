import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class Deployed extends StatefulWidget {
  const Deployed({super.key});

  @override
  State<Deployed> createState() => _DeployedState();
}

class _DeployedState extends State<Deployed> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Deployed',
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
        body: const DeployedPage(),
      ),
    );
  }
}

class DeployedPage extends StatelessWidget {
  const DeployedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 15),
        child: Switch(
          value: themeManager.isDarkMode ==
              ThemeMode.dark, // Check current theme mode
          onChanged: (bool value) {
            // Toggle the theme when the switch is changed
            themeManager.toggleTheme();
          },
          activeColor:
              AppColors.lightPrimary, // Color for active switch (light mode)
          inactiveTrackColor:
              Colors.grey[800], // Color for inactive track (dark mode)
          activeTrackColor:
              AppColors.yellow, // Color for active track (light mode)
        ),
      ),
    );
  }
}
