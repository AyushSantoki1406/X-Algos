import 'package:flutter/material.dart';
import 'package:xalgo/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/theme/theme_manage.dart';
import 'package:xalgo/theme/app_colors.dart';

class PaperTrade extends StatefulWidget {
  const PaperTrade({super.key});

  @override
  State<PaperTrade> createState() => _PaperTradeState();
}

class _PaperTradeState extends State<PaperTrade> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
        key: _scaffoldKey, // Assign the key to Scaffold
        endDrawer: AppDrawer(),
        backgroundColor: themeManager.isDarkMode == ThemeMode.dark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {},
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                pinned: true,
                backgroundColor: themeManager.isDarkMode == ThemeMode.dark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  'Paper Trade',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: themeManager.isDarkMode == ThemeMode.dark
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: themeManager.isDarkMode == ThemeMode.dark
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
                          color: themeManager.isDarkMode == ThemeMode.dark
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
            body: const PaperTradePage(),
          ),
        ));
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
