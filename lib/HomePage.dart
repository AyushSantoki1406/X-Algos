import 'package:flutter/material.dart';
import 'package:xalgo/Dashboard/Capital.dart';
import 'package:xalgo/Dashboard/DashboardAngel.dart';
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
  final GlobalKey<CapitalState> _capitalKey = GlobalKey<CapitalState>();
  final GlobalKey<DashboardAngelState> _AngleDashboardKey =
      GlobalKey<DashboardAngelState>();

  bool isRefreshing = false;

  Future<void> _reloadData() async {
    setState(() {
      isRefreshing = true;
    });

    // Call fetchData() from Capital widget
    _capitalKey.currentState?.fetchData();
    _AngleDashboardKey.currentState?.fetchData();

    await Future.delayed(Duration(seconds: 2)); // Simulate network delay

    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeProvider>(context);
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    print("helooooo ${themeManager.isDarkMode}");

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: AppDrawer(),
      backgroundColor: themeManager.isDarkMode
          ? AppColors.darkPrimary
          : AppColors.lightPrimary,
      body: Stack(
        children: [
          // RefreshIndicator for pull-to-refresh
          RefreshIndicator(
            onRefresh: _reloadData,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: themeManager.isDarkMode
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
                      color: themeManager.isDarkMode
                          ? AppColors.lightPrimary
                          : AppColors.darkPrimary,
                    ),
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: themeManager.isDarkMode
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
                      builder: (context) => IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: themeManager.isDarkMode
                              ? AppColors.lightPrimary
                              : AppColors.darkPrimary,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyAccountPage(),
                                settings: RouteSettings(),
                                fullscreenDialog: false,
                              ));
                        },
                      ),
                    ),
                  ],
                ),
              ],
              body: Column(
                children: [
                  Expanded(
                    child: Capital(
                        key: _capitalKey), // Assign key to access fetchData()
                  ),
                ],
              ),
            ),
          ),

          // Custom refresh logo animation when refreshing
          if (isRefreshing)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                  height: 80.0,
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Image.asset(
                    'assets/your_logo.png', // Replace with your logo path
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
