import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';

class Subcribed extends StatefulWidget {
  const Subcribed({super.key});

  @override
  State<Subcribed> createState() => _SubcribedState();
}

class _SubcribedState extends State<Subcribed> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
      final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: Scaffold(
            key: _scaffoldKey, // Assign the key to Scaffold
            endDrawer: AppDrawer(),
            backgroundColor: themeManager.themeMode == ThemeMode.dark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            body: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {},
              child: NestedScrollView(
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
                      'Subcribed',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: themeManager.themeMode == ThemeMode.dark
                              ? AppColors.lightPrimary
                              : AppColors.darkPrimary),
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),
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
                body: const SubcribedPage(),
              ),
            )));
  }
}

class SubcribedPage extends StatelessWidget {
  const SubcribedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center();
  }
}
