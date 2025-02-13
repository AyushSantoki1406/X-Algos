import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:developer';

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
  var selectedMonthRoi;

  @override
  void initState() {
    super.initState();
    selectedMonths =
        List.generate(widget.allSheetData.length, (_) => DateTime.now());
    selectedYears =
        List.generate(widget.allSheetData.length, (_) => DateTime.now().year);
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

  Map<String, double> getMonthlyAccuracy(List<dynamic> updatedAllSheetData) {
    for (var sheet in updatedAllSheetData) {
      if (sheet is Map && sheet.containsKey('monthlyAccuracy')) {
        final monthlyAccuracy = sheet['monthlyAccuracy'];

        if (monthlyAccuracy is Map<String, dynamic>) {
          for (var entry in monthlyAccuracy.entries) {
            final month = entry.key;
            final accuracy = entry.value;

            if (accuracy is num) {
              monthlyAccuracyMap[month] = accuracy.toDouble();
            }
          }
        }
      }
    }

    // Sort map keys (months) in ascending order
    final sortedMonthlyAccuracy = Map.fromEntries(
      monthlyAccuracyMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );

    return sortedMonthlyAccuracy;
  }

  Map<String, double> getMonthlyRoi(List<dynamic> updatedAllSheetData) {
    Map<String, double> monthlyRoiMap = {};

    for (var sheet in updatedAllSheetData) {
      if (sheet is Map && sheet.containsKey('monthlyRoi')) {
        final monthlyRoi = sheet['monthlyRoi'];

        if (monthlyRoi is Map<String, dynamic>) {
          for (var entry in monthlyRoi.entries) {
            final month = entry.key;
            final roi = entry.value;

            if (roi is num) {
              monthlyRoiMap[month] = roi.toDouble();
            }
          }
        }
      }
    }

    // Sort map keys (months) in ascending order
    final sortedMonthlyRoi = Map.fromEntries(
      monthlyRoiMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return sortedMonthlyRoi;
  }

  @override
  Widget build(BuildContext context) {
    log("po ${widget.updatedAllSheetData[1]['monthlyAccuracy']}");
    print("zz ${widget.allSheetData}");
    return Column(
      children: widget.allSheetData
          .where((sheet) => sheet['UserId'] == widget.clientId)
          .map((filteredSheet) {
        final pnlByDate = generatePnlMap(filteredSheet['sheetData']);

        log("Final Monthly Accuracy: ${getMonthlyAccuracy(widget.updatedAllSheetData)}");

        var allUserIds =
            widget.updatedAllSheetData.map((sheet) => sheet['UserId']).toList();
        log('All UserIds: $allUserIds');
        log("Type of clientId: ${widget.clientId.runtimeType}");

        for (var userId in allUserIds) {
          log("Type of UserId: ${userId.runtimeType}");
        }

        if (allUserIds.contains(widget.clientId)) {
          for (var sheet in widget.updatedAllSheetData) {
            if (sheet['UserId'] == widget.clientId) {
              log('User datass: ${sheet['monthlyAccuracy']}');
            }
          }
        } else {
          log('ClientId not found in list');
        }

        final selectedMonth =
            selectedMonths[widget.allSheetData.indexOf(filteredSheet)];
        final selectedYear =
            selectedYears[widget.allSheetData.indexOf(filteredSheet)];
        final startOfMonth =
            DateTime(selectedMonth.year, selectedMonth.month, 1);
        final endOfMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
        var selectedMonthAccuracy;

        final days = List.generate(
          endOfMonth.difference(startOfMonth).inDays + 1,
          (index) => startOfMonth.add(Duration(days: index)),
        );

        final themeManager = Provider.of<ThemeManager>(context);

        void printSelectedMonthAccuracy() {
          final selectedMonth =
              selectedMonths[widget.allSheetData.indexOf(filteredSheet)];
          final selectedYear =
              selectedYears[widget.allSheetData.indexOf(filteredSheet)];

          final monthKey = "${selectedYear}-${selectedMonth.month}";

          setState(() {
            final monthlyAccuracy =
                getMonthlyAccuracy(widget.updatedAllSheetData);
            selectedMonthAccuracy = monthlyAccuracy[monthKey] ?? "--";
          });
        }

        void printCurrentMonthAccuracy() {
          final currentDate = DateTime.now();
          final currentMonth = currentDate.month;
          final currentYear = currentDate.year;

          // Construct a key for the current month with two-digit padding for the month
          final currentMonthKey =
              "$currentYear-${currentMonth.toString().padLeft(2, '0')}";
          log("Constructed Current Month Key: $currentMonthKey");

          // Get the accuracy map and extract the accuracy for the current month
          final monthlyAccuracy =
              getMonthlyAccuracy(widget.updatedAllSheetData);
          log("Monthly Accuracy Map: $monthlyAccuracy");

          // Log each key to inspect if there's any discrepancy
          log("Available keys in Monthly Accuracy Map: ${monthlyAccuracy.keys}");

          // Declare a variable to hold the accuracy for the current month
          double? currentMonthAccuracy;

          for (var entry in monthlyAccuracy.entries) {
            // Correctly normalize the month part of the key
            final parts = entry.key.split('-');
            final normalizedKey =
                "${parts[0]}-${parts[1].padLeft(2, '0')}"; // Only pad the month part

            log("Checking key: $normalizedKey");

            if (normalizedKey == currentMonthKey) {
              currentMonthAccuracy = entry.value;
              break; // Exit the loop once the correct key is found
            }
          }

          // Log the result and update the UI state
          if (currentMonthAccuracy != null) {
            log("Current Month Accuracy for Key $currentMonthKey: $currentMonthAccuracy");

            setState(() {
              selectedMonthAccuracy = currentMonthAccuracy;
            });
          } else {
            log("No accuracy found for Current Month Key: $currentMonthKey");

            setState(() {
              selectedMonthAccuracy = "--"; // Default value if no data
            });
          }

          // Print the final selectedMonthAccuracy value
          log("Selected Month Accuracy: $selectedMonthAccuracy");
        }

        void printCurrentMonthRoi() {
          final currentDate = DateTime.now();
          final currentMonth = currentDate.month;
          final currentYear = currentDate.year;

          // Construct a key for the current month with two-digit padding for the month
          final currentMonthKey =
              "$currentYear-${currentMonth.toString().padLeft(2, '0')}";
          log("Constructed Current Month Key: $currentMonthKey");

          // Get the monthly ROI map and extract the ROI for the current month
          final monthlyRoi = getMonthlyRoi(widget.updatedAllSheetData);
          log("Monthly ROI Map: $monthlyRoi");

          // Log each key to inspect if there's any discrepancy
          log("Available keys in Monthly ROI Map: ${monthlyRoi.keys}");

          // Declare a variable to hold the ROI for the current month
          double? currentMonthRoi;

          // Loop through the map entries and find the ROI for the current month
          for (var entry in monthlyRoi.entries) {
            // Correctly normalize the month part of the key
            final parts = entry.key.split('-');
            final normalizedKey =
                "${parts[0]}-${parts[1].padLeft(2, '0')}"; // Only pad the month part

            log("Checking key: $normalizedKey");

            if (normalizedKey == currentMonthKey) {
              currentMonthRoi = entry.value;
              break; // Exit the loop once the correct key is found
            }
          }

          // Log the result and update the UI state
          if (currentMonthRoi != null) {
            log("Current Month ROI for Key $currentMonthKey: $currentMonthRoi");

            setState(() {
              selectedMonthRoi = currentMonthRoi;
            });
          } else {
            log("No ROI found for Current Month Key: $currentMonthKey");

            setState(() {
              selectedMonthRoi = "--"; // Default value if no data
            });
          }

          // Print the final selectedMonthRoi value
          log("Selected Month ROI: $selectedMonthRoi");
        }

        setState(() {
          printCurrentMonthAccuracy();
          printCurrentMonthRoi();
        });

        void handleMonthChange(int sheetIndex, int month) {
          setState(() {
            selectedMonths[sheetIndex] =
                DateTime(selectedMonths[sheetIndex].year, month + 1, 1);
          });
          printSelectedMonthAccuracy(); // Print the accuracy after the month change
        }

        void handleYearChange(int sheetIndex, int year) {
          setState(() {
            selectedYears[sheetIndex] = year;
            selectedMonths[sheetIndex] =
                DateTime(year, selectedMonths[sheetIndex].month, 1);
          });
          printSelectedMonthAccuracy(); // Print the accuracy after the year change
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
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
                      margin: EdgeInsets.symmetric(vertical: 20),
                      child: GridView.builder(
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
                          final pnlList = pnlByDate[dateKey];

                          final pnl = pnlByDate[dateKey] ??
                              0.0; // Use default value if null

                          final isCurrentMonth =
                              day.month == selectedMonth.month;

                          // Determine background color based on P&L
                          Color backgroundColor = themeManager.themeMode ==
                                  ThemeMode.dark
                              ? AppColors
                                  .darkBackground // Dark mode background color
                              : AppColors.lightBackground;
                          if (pnl != null) {
                            if (pnl > 0) {
                              backgroundColor = themeManager.themeMode ==
                                      ThemeMode.dark
                                  ? Colors.green
                                      .shade700 // Dark mode background for positive P&L
                                  : Colors.green
                                      .shade400; // Light mode background for positive P&L
                            } else if (pnl < 0) {
                              backgroundColor = themeManager.themeMode ==
                                      ThemeMode.dark
                                  ? Colors.red
                                      .shade700 // Dark mode background for negative P&L
                                  : Colors.red
                                      .shade400; // Light mode background for negative P&L
                            }
                          }

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
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Accuracy",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                                selectedMonthAccuracy.toString() ??
                                    "--", // Provide a default value if it's null
                                style: TextStyle(
                                    fontSize: 16,
                                    color: selectedMonthAccuracy == null ||
                                            selectedMonthAccuracy == "--"
                                        ? Colors.grey
                                        : Colors
                                            .green, // Use green if available, else grey
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("ROI",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                                selectedMonthRoi.toString() ??
                                    "--", // Provide a default value if it's null
                                style: TextStyle(
                                    fontSize: 16,
                                    color: selectedMonthRoi == null ||
                                            selectedMonthRoi == "--"
                                        ? Colors.grey
                                        : Colors
                                            .green, // Use green if available, else grey
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
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
