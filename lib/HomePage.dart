import 'package:flutter/material.dart';
import 'package:xalgo/Dashboard/Capital.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/widgets/drawer_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey, // Assign the key to Scaffold
      endDrawer: AppDrawer(),
      backgroundColor: themeManager.themeMode == ThemeMode.dark
          ? AppColors.darkPrimary
          : AppColors.lightPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: themeManager.themeMode == ThemeMode.dark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              'Dashboard',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: themeManager.themeMode == ThemeMode.dark
                      ? AppColors.lightPrimary
                      : AppColors.darkPrimary),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: themeManager.themeMode == ThemeMode.dark
                    ? Image.asset(
                        'assets/images/darklogo.png',
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/lightlogo.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            actions: [
              Builder(
                // Ensure correct context
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu,
                      color: themeManager.themeMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Wrap Capital widget inside Expanded or Container with defined height
            Expanded(child: Capital()),
          ],
        ),
      ),
    );
  }
}
