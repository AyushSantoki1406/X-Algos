import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:developer';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:provider/provider.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'package:xalgo/theme/theme_manage.dart';

class MultiCalendar extends StatefulWidget {
  final int index2;
  final List<dynamic> allSheetData;
  final String clientId;
  final String selectedStrategy;
  final dynamic updatedAllSheetData;

  MultiCalendar({
    required this.index2,
    required this.allSheetData,
    required this.clientId,
    required this.selectedStrategy,
    required this.updatedAllSheetData,
  });

  @override
  _MultiCalendarState createState() => _MultiCalendarState();
}

class _MultiCalendarState extends State<MultiCalendar> {
  late List<DateTime> selectedMonths;
  late List<int> selectedYears;
  List<Map<String, dynamic>> selectedDatesAndPnl = [];
  final Map<String, double> monthlyAccuracyMap = {};
  Map<String, double> monthlyRoiMap = {};
  String? selectedMonthAccuracy = "0";
  String? selectedMonthRoi = "0";

  @override
  void initState() {
    super.initState();
    selectedMonths =
        List.generate(widget.allSheetData.length, (_) => DateTime.now());
    selectedYears =
        List.generate(widget.allSheetData.length, (_) => DateTime.now().year);
    currentMonthlyAccuracy();
  }

  // Generate a map of date -> P&L

  Map<String, double> generatePnlMap(List<dynamic> sheetData) {
    final Map<String, double> pnlMap = {};

    for (var entry in sheetData) {
      // Ensure entry has at least 11 elements before accessing indexes
      if (entry is List && entry.length > 10) {
        try {
          final date = DateFormat('yyyy-MM-dd').format(
              DateTime.parse(entry[3].toString())); // Convert to string first

          var pnl = entry[10];

          // Convert P&L to double if it's a String
          if (pnl is String) {
            pnl =
                double.tryParse(pnl) ?? 0.0; // Default to 0.0 if parsing fails
          } else if (pnl is! double) {
            pnl = 0.0; // Ensure pnl is a valid number
          }

          // Sum P&L for the same date
          pnlMap[date] = ((pnlMap[date] ?? 0.0) + pnl);
        } catch (e) {
          print("Error processing entry: $entry, Error: $e");
        }
      } else {
        print("Skipping invalid entry: $entry");
      }
    }

    // Format all values to 2 decimal places
    pnlMap.updateAll((key, value) => double.parse(value.toStringAsFixed(2)));

    return pnlMap;
  }

  void currentMonthlyAccuracy([String? passedMonthKey, String? passedYear]) {
    var allUserIds =
        widget.updatedAllSheetData.map((sheet) => sheet['UserId']).toList();

    if (allUserIds.contains(widget.clientId)) {
      for (var sheet in widget.updatedAllSheetData) {
        if (sheet['UserId'] == widget.clientId) {
          log('User data: ${sheet['monthlyAccuracy']}');

          String currentMonthKey;
          if (passedMonthKey == null && passedYear == null) {
            final currentDate = DateTime.now();
            currentMonthKey = "${currentDate.year}-${currentDate.month}";
          } else {
            currentMonthKey = passedYear != null
                ? "$passedYear-${int.parse(passedMonthKey!)}"
                : passedMonthKey!;
            if (currentMonthKey.contains("-")) {
              var parts = currentMonthKey.split("-");
              currentMonthKey = "${parts[0]}-${int.parse(parts[1])}";
            }
          }

          log("Using selected key: $currentMonthKey");

          if (sheet['monthlyAccuracy'] is Map) {
            Map<String, dynamic> monthlyAccuracyData = sheet['monthlyAccuracy'];
            if (monthlyAccuracyData.containsKey(currentMonthKey)) {
              var value = monthlyAccuracyData[currentMonthKey];
              setState(() {
                selectedMonthAccuracy = value.toStringAsFixed(2);
              });
              log("Found value for $currentMonthKey: $value");
            } else {
              log("Month not found for key: $currentMonthKey");
              setState(() {
                selectedMonthAccuracy = "null";
              });
            }
          }
        }
      }
    } else {
      log('ClientId not found in list');
    }

    void currentMonthlyROI([String? passedMonthKey, String? passedYear]) {
      var allUserIds =
          widget.updatedAllSheetData.map((sheet) => sheet['UserId']).toList();

      if (allUserIds.contains(widget.clientId)) {
        for (var sheet in widget.updatedAllSheetData) {
          if (sheet['UserId'] == widget.clientId) {
            log('User data: ${sheet['monthlyRoi']}');

            String currentMonthKey;
            if (passedMonthKey == null && passedYear == null) {
              final currentDate = DateTime.now();
              currentMonthKey = "${currentDate.year}-${currentDate.month}";
            } else {
              currentMonthKey = passedYear != null
                  ? "$passedYear-${int.parse(passedMonthKey!)}"
                  : passedMonthKey!;
              if (currentMonthKey.contains("-")) {
                var parts = currentMonthKey.split("-");
                currentMonthKey = "${parts[0]}-${int.parse(parts[1])}";
              }
            }

            log("Using selected key: $currentMonthKey");

            if (sheet['monthlyRoi'] is Map) {
              Map<String, dynamic> monthlyAccuracyData = sheet['monthlyRoi'];
              if (monthlyAccuracyData.containsKey(currentMonthKey)) {
                var value = monthlyAccuracyData[currentMonthKey];
                setState(() {
                  selectedMonthRoi = value.toStringAsFixed(2);
                });
                log("Found value for $currentMonthKey: $value");
              } else {
                log("Month not found for key: $currentMonthKey");
                setState(() {
                  selectedMonthRoi = "null";
                });
              }
            }
          }
        }
      } else {
        log('ClientId not found in list');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.allSheetData
          .where((sheet) => sheet['UserId'] == widget.clientId)
          .map((filteredSheet) {
        final pnlByDate = generatePnlMap(filteredSheet['sheetData']);
        final themeManager = Provider.of<ThemeManager>(context);

        var allUserIds =
            widget.updatedAllSheetData.map((sheet) => sheet['UserId']).toList();

        final selectedMonth =
            selectedMonths[widget.allSheetData.indexOf(filteredSheet)];
        final selectedYear =
            selectedYears[widget.allSheetData.indexOf(filteredSheet)];
        final startOfMonth =
            DateTime(selectedMonth.year, selectedMonth.month, 1);
        final endOfMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

        final days = List.generate(
          endOfMonth.difference(startOfMonth).inDays + 1,
          (index) => startOfMonth.add(Duration(days: index)),
        );

        void currentMonthlyAccuracy(
            [String? passedMonthKey, String? passedYear]) {
          if (allUserIds.contains(widget.clientId)) {
            for (var sheet in widget.updatedAllSheetData) {
              if (sheet['UserId'] == widget.clientId) {
                log('User data: ${sheet['monthlyAccuracy']}');

                String currentMonthKey;

                if (passedMonthKey == null && passedYear == null) {
                  final currentDate = DateTime.now();
                  final currentMonth = currentDate.month;
                  final currentYear = currentDate.year;

                  // Format the current month as "YYYY-M" (no leading zero for the month)
                  currentMonthKey = "$currentYear-${currentMonth}";
                } else {
                  // If passedMonthKey or passedYear is provided, format it dynamically
                  currentMonthKey = passedYear != null
                      ? "$passedYear-${int.parse(passedMonthKey!)}"
                      : passedMonthKey!;

                  // Remove leading zero from the month part if it exists
                  if (currentMonthKey.contains("-")) {
                    var parts = currentMonthKey.split("-"); // e.g., "2025-02"
                    currentMonthKey =
                        "${parts[0]}-${int.parse(parts[1]).toString()}"; // Remove leading zero
                  }
                }

                log("Using selected key: $currentMonthKey"); // Log the selected key

                if (sheet['monthlyAccuracy'] is Map) {
                  Map<String, dynamic> monthlyAccuracyData =
                      sheet['monthlyAccuracy'];

                  // Look for the provided month key in the data
                  if (monthlyAccuracyData.containsKey(currentMonthKey)) {
                    var value = monthlyAccuracyData[currentMonthKey];
                    setState(() {
                      selectedMonthAccuracy = value.toStringAsFixed(2);
                    });
                    log("Found value for $currentMonthKey: $value");
                  } else {
                    log("Month not found for key: $currentMonthKey");
                    setState(() {
                      selectedMonthAccuracy = "null";
                    });
                  }
                }
              }
            }
          } else {
            log('ClientId not found in list'); // Log if client ID is not found
          }
        }

        void currentMonthlROI([String? passedMonthKey, String? passedYear]) {
          if (allUserIds.contains(widget.clientId)) {
            for (var sheet in widget.updatedAllSheetData) {
              if (sheet['UserId'] == widget.clientId) {
                log('User data: ${sheet['monthlyRoi']}'); // Log user data for debugging

                // Use passedMonthKey and passedYear or calculate default
                String currentMonthKey;

                if (passedMonthKey == null && passedYear == null) {
                  final currentDate = DateTime.now();
                  final currentMonth = currentDate.month;
                  final currentYear = currentDate.year;

                  // Format the current month as "YYYY-M" (no leading zero for the month)
                  currentMonthKey = "$currentYear-${currentMonth}";
                } else {
                  // If passedMonthKey or passedYear is provided, format it dynamically
                  currentMonthKey = passedYear != null
                      ? "$passedYear-${int.parse(passedMonthKey!)}"
                      : passedMonthKey!;

                  // Remove leading zero from the month part if it exists
                  if (currentMonthKey.contains("-")) {
                    var parts = currentMonthKey.split("-"); // e.g., "2025-02"
                    currentMonthKey =
                        "${parts[0]}-${int.parse(parts[1]).toString()}"; // Remove leading zero
                  }
                }

                log("Using selected key: $currentMonthKey"); // Log the selected key

                if (sheet['monthlyRoi'] is Map) {
                  Map<String, dynamic> monthlyAccuracyData =
                      sheet['monthlyRoi'];

                  // Look for the provided month key in the data
                  if (monthlyAccuracyData.containsKey(currentMonthKey)) {
                    var value = monthlyAccuracyData[currentMonthKey];
                    setState(() {
                      selectedMonthRoi = value.toStringAsFixed(2);
                    });
                    log("Found value for $currentMonthKey: $value");
                  } else {
                    log("Month not found for key: $currentMonthKey");
                    setState(() {
                      selectedMonthRoi = "null";
                    });
                  }
                }
              }
            }
          } else {
            log('ClientId not found in list'); // Log if client ID is not found
          }
        }

        void handleMonthChange(int sheetIndex, int month) {
          setState(() {
            selectedMonths[sheetIndex] =
                DateTime(selectedMonths[sheetIndex].year, month + 1, 1);
          });

          // Pass the dynamic key for selected month and year
          currentMonthlyAccuracy("${selectedMonths[sheetIndex].month}",
              "${selectedMonths[sheetIndex].year}");
          currentMonthlROI("${selectedMonths[sheetIndex].month}",
              "${selectedMonths[sheetIndex].year}");
        }

        void handleYearChange(int sheetIndex, int year) {
          setState(() {
            selectedYears[sheetIndex] = year;
            selectedMonths[sheetIndex] =
                DateTime(year, selectedMonths[sheetIndex].month, 1);
          });

          // Pass the dynamic key for selected year and month
          currentMonthlyAccuracy(
              "${selectedMonths[sheetIndex].month}", "$year");
          currentMonthlROI("${selectedMonths[sheetIndex].month}", "$year");
        }

        print("????????????????? ${selectedMonthAccuracy}");

        double accuracy = double.tryParse(selectedMonthAccuracy ?? "0") ?? 0;
        double progress = accuracy / 100;
        double roi = double.tryParse(selectedMonthRoi ?? "0") ?? 0;
        double progress2 = roi / 100;

        return Container(
          margin: const EdgeInsets.only(bottom: 0, left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<int>(
                    value: selectedMonth.month - 1,
                    onChanged: (newMonth) {
                      if (newMonth != null) {
                        handleMonthChange(
                            widget.allSheetData.indexOf(filteredSheet),
                            newMonth);
                      }
                    },
                    items: List.generate(12, (index) {
                      final monthName = DateFormat('MMMM')
                          .format(DateTime(selectedMonth.year, index + 1, 1));
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(monthName,
                            style: TextStyle(
                                color: themeManager.themeMode == ThemeMode.dark
                                    ? AppColors.lightPrimary
                                    : AppColors.darkPrimary)),
                      );
                    }),
                  ),
                  SizedBox(width: 50),
                  DropdownButton<int>(
                    value: selectedYear,
                    onChanged: (newYear) {
                      if (newYear != null) {
                        handleYearChange(
                            widget.allSheetData.indexOf(filteredSheet),
                            newYear);
                      }
                    },
                    items: List.generate(10, (index) {
                      final year = DateTime.now().year - (9 - index);
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                              color: themeManager.themeMode == ThemeMode.dark
                                  ? AppColors.lightPrimary
                                  : AppColors.darkPrimary),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              // Calendar Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 0),
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, // 7 columns for days of the week
                          childAspectRatio: 1,
                          crossAxisSpacing: 4, // Space between columns
                          mainAxisSpacing: 4, // Space between rows
                        ),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        // padding: EdgeInsets.only(
                        //     left: 50,
                        //     right: 50,
                        //     top: 50,
                        //     bottom: 50), // Padding around the grid
                        itemCount: days.length +
                            days.first.weekday % 7 +
                            7, // Adjusted count

                        itemBuilder: (context, index) {
                          if (index < 7) {
                            // Weekday Labels
                            final dayOfWeek =
                                ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index];
                            return Center(
                              child: Text(
                                dayOfWeek,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color:
                                      themeManager.themeMode == ThemeMode.dark
                                          ? AppColors.lightPrimary
                                          : AppColors.darkPrimary,
                                ),
                              ),
                            );
                          }

                          final adjustedIndex = index - 7;
                          if (adjustedIndex < days.first.weekday % 7) {
                            // Empty spaces for alignment
                            return Container();
                          }

                          final day =
                              days[adjustedIndex - days.first.weekday % 7];
                          final dateKey = DateFormat('yyyy-MM-dd').format(day);
                          final List<double> pnlList = (pnlByDate[dateKey]
                                  is List)
                              ? (pnlByDate[dateKey] as List)
                                  .map((e) => e as double)
                                  .toList()
                              : pnlByDate[dateKey] is double
                                  ? [pnlByDate[dateKey] as double]
                                  : []; // Default to empty list if pnlByDate[dateKey] is neither List nor double

                          print("mjkiuhgrtghh $pnlList");

                          List<double> allProfits = [];

// Extract only positive PNL values
                          for (var entry in pnlByDate.entries) {
                            final List<double> pnlList = (entry.value is List)
                                ? (entry.value as List)
                                    .map((e) => e as double)
                                    .toList()
                                : entry.value is double
                                    ? [entry.value as double]
                                    : []; // Default to empty list

                            print("alllistis $pnlList");

                            allProfits.addAll(pnlList);
                          }

// Find the maximum profit (handle case when list is empty)
                          double maxProfit = allProfits.isNotEmpty
                              ? allProfits.reduce((a, b) => a > b ? a : b)
                              : 1;

                          double maxLoss =
                              allProfits.reduce((a, b) => a < b ? a : b);

                          print("allprofit $allProfits");

                          print("Maximum Profit: $maxLoss");

                          // List<double> lossLevels = [
                          //   -maxProfit * 0.2,
                          //   -maxProfit * 0.4,
                          //   -maxProfit * 0.6,
                          //   -maxProfit * 0.8,
                          // ];

// Function to determine color based on profit/loss levels
                          Color getPnlColor(double pnl) {
                            if (pnl > 0) {
                              double percentage = (pnl / maxProfit) * 100;

                              if (percentage <= 20) {
                                return Color.fromRGBO(
                                    160, 235, 160, 1); // Soft Mint Green
                              } else if (percentage <= 40) {
                                return Color.fromRGBO(
                                    80, 200, 120, 1); // Fresh Grass Green
                              } else if (percentage <= 60) {
                                return Color.fromRGBO(
                                    50, 180, 90, 1); // Rich Forest Green
                              } else if (percentage <= 80) {
                                return Color.fromRGBO(
                                    20, 150, 70, 1); // Deep Emerald Green
                              } else {
                                return Color.fromRGBO(
                                    56, 205, 56, 1); // Intense Pine Green
                              }
                            } else if (pnl < 0) {
                              double percentage = (pnl / maxLoss) * 100;
                              print("ayushji $percentage");
                              if (percentage >= 20) {
                                return Color.fromRGBO(254, 141, 141, 1);
                              } else if (percentage >= 40) {
                                return Color.fromRGBO(
                                    255, 126, 114, 1); // Medium Red
                              } else if (percentage >= 60) {
                                return Color.fromRGBO(
                                    255, 105, 105, 1); // Dark Red
                              } else if (percentage >= 80) {
                                return Color.fromRGBO(
                                    255, 55, 55, 1); // Darker Red
                              } else {
                                return Color.fromRGBO(
                                    255, 60, 60, 1); // Deepest Red
                              }
                            }

                            // Default background color
                            return Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground;
                          }

                          final pnl = pnlByDate[dateKey] ?? 0.0;
                          final isCurrentMonth =
                              day.month == selectedMonth.month;
                          Color backgroundColor = getPnlColor(pnl);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // Clear previous selection and add the new one
                                selectedDatesAndPnl = [
                                  {'date': dateKey, 'pnl': pnl},
                                ];
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.zero, // Remove extra spacing
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentMonth
                                        ? themeManager.themeMode ==
                                                ThemeMode.dark
                                            ? AppColors.lightBackground
                                            : AppColors.darkBackground
                                        : (themeManager.themeMode ==
                                                ThemeMode.dark
                                            ? AppColors.darkBackground
                                            : AppColors.lightBackground),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.only(left: 20, right: 20, top: 30),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("Accuracy",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              CircularPercentIndicator(
                                radius: 30.0,
                                lineWidth: 5.0,
                                percent: progress.clamp(
                                    0, 1), // Ensures value is between 0-1
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$accuracy%", // Accuracy value displayed inside
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? AppColors.lightPrimary
                                              : AppColors.darkPrimary),
                                    ),
                                  ],
                                ),
                                progressColor: progress < 0.33
                                    ? Colors.red
                                    : progress < 0.67
                                        ? Colors.orange
                                        : Colors
                                            .green, // Dynamically change color
                                backgroundColor: Colors.grey[300]!,
                                circularStrokeCap: CircularStrokeCap.round,
                                animation: true,
                                animationDuration: 1500, // Smooth animation
                              ),
                            ],
                          ),
                          SizedBox(width: 20),
                          SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("ROI",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              CircularPercentIndicator(
                                radius: 30.0,
                                lineWidth: 5.0,
                                percent: progress2.clamp(
                                    0, 1), // Ensures value is between 0-1
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$roi%", // Accuracy value displayed inside
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: themeManager.themeMode ==
                                                  ThemeMode.dark
                                              ? AppColors.lightPrimary
                                              : AppColors.darkPrimary),
                                    ),
                                  ],
                                ),
                                progressColor: Colors.blue,
                                backgroundColor: Colors.grey[300]!,
                                circularStrokeCap: CircularStrokeCap.round,
                                animation: true,
                                animationDuration: 1500, // Smooth animation
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                  height:
                      20), // Space between the calendar and the date/P&L display
              Text(
                "Selected Date and P&L:",
                style: TextStyle(
                    color: themeManager.themeMode == ThemeMode.dark
                        ? AppColors.lightPrimary
                        : AppColors.darkPrimary),
              ),
              Column(
                children: selectedDatesAndPnl.map((entry) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['date'],
                        style: TextStyle(
                            color: themeManager.themeMode == ThemeMode.dark
                                ? AppColors.lightPrimary
                                : AppColors.darkPrimary),
                      ),
                      Text(
                        entry['pnl'].toString(),
                        style: TextStyle(
                            color: themeManager.themeMode == ThemeMode.dark
                                ? AppColors.lightPrimary
                                : AppColors.darkPrimary),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
