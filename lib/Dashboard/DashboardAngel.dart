import 'dart:convert'; // Add this import for jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:xalgo/Dashboard/Capital.dart';
import 'package:http/http.dart' as http;
import 'package:xalgo/ExtraFunction/MultiCalendar.dart';
import 'package:xalgo/secret/secret.dart';
import 'package:xalgo/theme/app_colors.dart';
import 'dart:developer';

import 'package:xalgo/theme/theme_manage.dart';

class DashboardAngel extends StatefulWidget {
  final List<dynamic> capital; // Define the capital parameter
  final bool darkMode; // Define the darkMode parameter

  const DashboardAngel({
    Key? key,
    required this.capital,
    required this.darkMode,
  }) : super(key: key);

  @override
  State<DashboardAngel> createState() => _DashboardAngel();
}

class _DashboardAngel extends State<DashboardAngel>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  List? brokerInfo = [];
  Map<String, dynamic>? userSchema; // Change to a Map to hold userSchema data
  String? email = "";
  bool isExpanded = false;
  bool isMobile = false;
  List allSheetData = [];
  Map<String, dynamic> dailyPnL = {};
  dynamic updatedAllSheetData;
  String selectedStrategy = "Select strategy";
  List<String> strategyOptions = [];
  bool loader = false;
  String clientId = ""; // Selected clientId
  Map<String, List<String>> clientStrategyMap = {
    'userId': ['Select Strategy', 'Strategy1', 'Strategy2'],
  };
  Map<String, dynamic> selectedStrategies = {};
  List<String> ids = [];
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    fetchData(); // Call fetchData on init
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat();
    _dotAnimation = IntTween(begin: 0, end: 2)
        .animate(_controller); // For 3 dots, cycling through 0, 1, 2
  }

  void fetchData() async {
    setState(() {
      isLoading = true;
    });

    String? userSchemaStr =
        (await secureStorage.read(key: 'userSchema'))?.toString();

    if (userSchemaStr != null) {
      setState(() {
        userSchema = jsonDecode(userSchemaStr);
      });
      print(userSchema?['DeployedData']);

      List<String> ids2 =
          (userSchema?['DeployedData'] as List? ?? []).where((data) {
        return data['Account'] == "Paper Trade";
      }).map((data) {
        return data['Strategy'] as String;
      }).toList();

      final Email = await secureStorage.read(key: 'Email');
      final aa = await secureStorage.read(key: 'allClientData');

      setState(() {
        email = Email;
        ids = ids2;
        brokerInfo = aa != null ? jsonDecode(aa) as List : [];
      });

      print("Response Body: ${email}");
      if (email != null) {
        fetchExcelSheet();
      }
    }
  }

  void fetchExcelSheet() async {
    try {
      // Ensure email is available
      if (email == null) {
        print("Email is null, cannot fetch Excel sheet data.");
        return;
      }

      final response = await http.post(
        Uri.parse("${Secret.backendUrl}/getMarketPlaceData"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);
      final List<dynamic> data = responseData['allData'];

      final filteredData =
          data.where((item) => ids.contains(item['_id'])).toList();

      print("filtered data: $filteredData");

      // Cast each item in filteredData to Map<String, dynamic> safely
      List<Map<String, dynamic>> mergedData = filteredData.map((item) {
        Map<String, dynamic> strategy = item as Map<String, dynamic>;

        final deployedInfo = userSchema?['DeployedData']?.firstWhere(
          (data) => data['Strategy'].toString() == strategy['_id'].toString(),
          orElse: () => null,
        );

        print(
            "Deployed Info: $deployedInfo"); // Debug print to check deployedInfo

        return {
          ...strategy,
          'AppliedDate':
              deployedInfo != null ? deployedInfo['AppliedDate'] : 'N/A',
          'Index': deployedInfo != null ? deployedInfo['Index'] : 'N/A',
        };
      }).toList();

      final response3 = await http.post(
        Uri.parse("${Secret.backendUrl}/fetchAllSheetData"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data3 = jsonDecode(response3.body);
      print("Response data: $data3"); // Debug print to check the response data

      if (data3 is Map<String, dynamic> && data3.containsKey('allSheetData')) {
        final allSheetData = data3['allSheetData'] as List<dynamic>;

        setState(() {
          this.allSheetData = allSheetData;
        });

        print(
            "All Sheet Data: $allSheetData"); // Debug print to check allSheetData
      }

      if (allSheetData.length > 0) {
        List<Map<String, dynamic>> updatedSheetData =
            (data3['allSheetData'] as List<dynamic>)
                .map<Map<String, dynamic>>((sheet) {
          Map<String, double> pnlByDate = {};
          Map<String, Map<String, double>> monthlyMetrics = {};
          int totalTrades = 0;
          int successfulTrades = 0;
          double totalInvestment = 0;
          double totalProfit = 0;

          // Ensure `sheetData` exists and is a non-empty list
          if (sheet['sheetData'] != null && sheet['sheetData'] is List) {
            for (var trade in sheet['sheetData']) {
              if (trade is List && trade.length > 10) {
                String? date = trade[3]?.toString();
                double? pnl = double.tryParse(trade[10].toString());
                double? investment = double.tryParse(trade[5].toString());

                print(
                    "Trade Date: $date, PnL: $pnl, Investment: $investment"); // Debug print for trade details

                if (date != null && pnl != null) {
                  DateTime? tradeDate;
                  try {
                    tradeDate = DateTime.parse(date);
                  } catch (e) {
                    print(
                        "Invalid date format: $date"); // Print error if the date is invalid
                    continue;
                  }

                  String month = "${tradeDate.year}-${tradeDate.month}";
                  pnlByDate[date] = (pnlByDate[date] ?? 0) + pnl;

                  // Initialize monthly metrics
                  monthlyMetrics[month] ??= {
                    'totalTrades': 0,
                    'successfulTrades': 0,
                    'totalInvestment': 0,
                    'totalProfit': 0,
                  };

                  // Accumulate monthly metrics
                  monthlyMetrics[month]!['totalTrades'] =
                      monthlyMetrics[month]!['totalTrades']! + 1;
                  if (pnl > 0) {
                    monthlyMetrics[month]!['successfulTrades'] =
                        monthlyMetrics[month]!['successfulTrades']! + 1;
                  }
                  if (investment != null && investment > 0) {
                    monthlyMetrics[month]!['totalInvestment'] =
                        monthlyMetrics[month]!['totalInvestment']! + investment;
                    monthlyMetrics[month]!['totalProfit'] =
                        monthlyMetrics[month]!['totalProfit']! + pnl;
                  }

                  // Accumulate totals
                  totalTrades++;
                  if (pnl > 0) {
                    successfulTrades++;
                  }
                  if (investment != null && investment > 0) {
                    totalInvestment += investment;
                    totalProfit += pnl;
                  }
                }
              }
            }
          }

          print(
              "Monthly Metrics: $monthlyMetrics"); // Debug print for monthly metrics
          print(
              "Total Trades: $totalTrades, Successful Trades: $successfulTrades"); // Debug print for totals

          double tradeAccuracy =
              totalTrades > 0 ? (successfulTrades / totalTrades) * 100 : 0;
          double roi =
              totalInvestment > 0 ? (totalProfit / totalInvestment) * 100 : 0;

          print(
              "Trade Accuracy: $tradeAccuracy, ROI: $roi"); // Debug print for accuracy and ROI

          Map<String, double> monthlyAccuracy = {};
          Map<String, double> monthlyRoi = {};

          monthlyMetrics.forEach((month, metrics) {
            int totalTrades = (metrics['totalTrades'] ?? 0).toDouble().toInt();
            int successfulTrades =
                (metrics['successfulTrades'] ?? 0).toDouble().toInt();

            double totalInvestment =
                (metrics['totalInvestment'] ?? 0).toDouble();
            double totalProfit = (metrics['totalProfit'] ?? 0).toDouble();

            double accuracy =
                totalTrades > 0 ? (successfulTrades / totalTrades) * 100 : 0;
            double roi =
                totalInvestment > 0 ? (totalProfit / totalInvestment) * 100 : 0;

            monthlyAccuracy[month] = accuracy;
            monthlyRoi[month] = roi;
          });

          print('aacur ${monthlyAccuracy}');
          return {
            ...sheet,
            'pnlByDate': pnlByDate,
            'tradeAccuracy': tradeAccuracy.toStringAsFixed(2),
            'rio': roi.toStringAsFixed(2),
            'monthlyAccuracy': monthlyAccuracy,
            'monthlyRoi': monthlyRoi,
          };
        }).toList();

        log("updatedAllSheetData is null, not a Map, or does not contain 'sheetData'.updatedAllSheetData is null, not a Map, or does not contain 'sheetData'.${updatedSheetData.toString()}"); // Debug print to check updated sheet data
        Map<dynamic, Set<String>> strategyMap = {};

        // Loop through the updatedSheetData and populate strategyMap
        for (var item in updatedSheetData) {
          dynamic userId = item['UserId']; // UserId
          String strategyName = item['strategyName']; // strategyName

          if (!strategyMap.containsKey(userId)) {
            // If the userId doesn't exist in the map, initialize it with an empty Set
            strategyMap[userId] = Set<String>();
          }

          // Add the strategyName to the Set for this UserId
          strategyMap[userId]!.add(strategyName);
        }

        // Convert the Set to List and add "Select Strategy" as the first element
        Map<dynamic, List<String>> strategyMapWithArrays = {};

        strategyMap.forEach((key, value) {
          // Convert the Set to List and add "Select Strategy" at the start
          List<String> strategiesList = List<String>.from(value);
          strategiesList.insert(0, "Select Strategy");

          // Add the list to the new map
          strategyMapWithArrays[key] = strategiesList;
        });

        // Print the final strategyMapWithArrays to debug
        print("Strategy Map with Arrays: $strategyMapWithArrays");

        if (mounted) {
          setState(() {
            updatedAllSheetData = updatedSheetData;
            clientStrategyMap = Map<String, List<String>>.from(
                strategyMapWithArrays
                    .map((key, value) => MapEntry(key, value)));
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error while fetching Excel sheet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: brokerInfo?.length ?? 0, // ✅ Prevent out-of-range access
      itemBuilder: (context, index) {
        if (brokerInfo == null || brokerInfo!.isEmpty) {
          return Center(child: Text("No Data Available"));
        }

        final item = brokerInfo![index]; // ✅ Safe access
        print("from ${item}");
        final clientId = item?['userData'] != null
            ? item['userData']['data']['clientcode']
            : item?['balances']?['result']?[0]?['user_id']?.toString();

        print("xyz updatedAllSheetData value: $updatedAllSheetData");

        void handleStrategyChange(String clientId, String strategy) {
          setState(() {
            selectedStrategies[clientId] = strategy;
          });
        }

        print("xyz ${updatedAllSheetData}");

        var lastSheet = updatedAllSheetData?.isNotEmpty == true
            ? updatedAllSheetData!.last
            : null;
        var sheetData = lastSheet?['sheetData'];
        var lastObject = sheetData?.isNotEmpty == true ? sheetData!.last : null;

        var lastValue = lastObject != null ? lastObject[10] : null;

        print("poi $lastValue");

        final themeManager = Provider.of<ThemeManager>(context);

        return Container(
          padding: EdgeInsets.only(left: 8, right: 8),
          margin: EdgeInsets.only(bottom: 10),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          _buildAccountItem(
                            "Name",
                            item['userData'] != null
                                ? (item['userData']['data']['name']?.length ?? 0) >
                                        30
                                    ? item['userData']['data']['name']!
                                            .substring(0, 30) +
                                        "..."
                                    : item['userData']['data']['name']
                                : (item['userDetails']['result']['first_name'] +
                                                item['userDetails']['result']
                                                    ['last_name'])
                                            ?.length ??
                                        0 > 30
                                    ? (item['userDetails']['result']['first_name'] +
                                                item['userDetails']['result']
                                                    ['last_name'])
                                            .substring(0, 30) +
                                        "..."
                                    : (item['userDetails']['result']
                                                ['first_name'] +
                                            item['userDetails']['result']
                                                ['last_name']) ??
                                        "N/A",
                          ),
                          _buildAccountItem("Broker",
                              item['userData'] != null ? "AngelOne" : "Delta"),
                          _buildAccountItem(
                              "UserId",
                              item['userData'] != null
                                  ? item['userData']['data']['clientcode']
                                  : item['balances']['result'][0]['user_id'] ??
                                      "N/A"),
                          _buildAccountItem(
                            "Active Strategy",
                            userSchema?['ActiveStrategys']?.toString() ?? "N/A",
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Card(
                        elevation: 3,
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 20, left: 20, right: 20, bottom: 20),
                          child: Column(
                            children: [
                              _statItem(
                                  "Account Balance",
                                  item['userData'] != null &&
                                          index < widget.capital.length
                                      ? Container(
                                          child: Text(
                                            '₹${(double.tryParse(widget.capital[index]['net'].toString()) ?? 0.0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: (item?['balances']
                                                              ?.result[0]
                                                              ?.balance_inr !=
                                                          null &&
                                                      double.tryParse(item?[
                                                                      'balances']
                                                                  ?.result[0]
                                                                  ?.balance_inr
                                                                  ?.toString() ??
                                                              "0.0")! <
                                                          0.0)
                                                  ? Colors
                                                      .red // Red if less than 0
                                                  : Colors
                                                      .green, // Green if greater than or equal to 0
                                            ),
                                          ),
                                        )
                                      : Text(
                                          '₹${double.tryParse(item?['balances']?.result[0]?.balance_inr?.toString() ?? "0.0")?.toStringAsFixed(2) ?? ""}',
                                          style: TextStyle(
                                            color: (double.tryParse(item?[
                                                                    'balances']
                                                                ?.result[0]
                                                                ?.balance_inr
                                                                ?.toString() ??
                                                            "0.0") ??
                                                        0.0) >
                                                    0.0
                                                ? Colors
                                                    .green // Green if greater than 0
                                                : Colors
                                                    .red, // Red if less than or equal to 0
                                          ),
                                        )),
                              Divider(
                                color: Colors.grey, // Line color
                                thickness: 1, // Line thickness
                                indent: 0, // Space before the line starts
                                endIndent: 0, // Space after the line ends
                              ),
                              _statItem("Overall gain", Text('0')),
                              Divider(
                                color: Colors.grey, // Line color
                                thickness: 1, // Line thickness
                                indent: 0, // Space before the line starts
                                endIndent: 0, // Space after the line ends
                              ),
                              _statItem("Monthly gain", Text('0%')),
                              Divider(
                                color: Colors.grey, // Line color
                                thickness: 1, // Line thickness
                                indent: 0, // Space before the line starts
                                endIndent: 0, // Space after the line ends
                              ),
                              _statItem("Today's gain", Text('0%')),
                              Divider(
                                color: Colors.grey, // Line color
                                thickness: 1, // Line thickness
                                indent: 0, // Space before the line starts
                                endIndent: 0, // Space after the line ends
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        // This centers the entire container
                        child: isLoading
                            ? Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                height: 37,
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: Center(
                                  // Center the content inside the loading spinner container
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      AnimatedBuilder(
                                        animation: _dotAnimation,
                                        builder: (context, child) {
                                          return Text(
                                            '.',
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: _dotAnimation.value == 0
                                                  ? Colors.white
                                                  : Colors
                                                      .grey, // White when it's 0, else gray
                                            ),
                                          );
                                        },
                                      ),
                                      AnimatedBuilder(
                                        animation: _dotAnimation,
                                        builder: (context, child) {
                                          return Text(
                                            '.',
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: _dotAnimation.value == 1
                                                  ? Colors.white
                                                  : Colors
                                                      .grey, // White when it's 1, else gray
                                            ),
                                          );
                                        },
                                      ),
                                      AnimatedBuilder(
                                        animation: _dotAnimation,
                                        builder: (context, child) {
                                          return Text(
                                            '.',
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: _dotAnimation.value == 2
                                                  ? Colors.white
                                                  : Colors
                                                      .grey, // White when it's 2, else gray
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  // Use Column to provide a bounded width constraint
                                  children: [
                                    clientStrategyMap[clientId]?.isNotEmpty ==
                                            true
                                        ? Card(
                                            elevation: 3,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.8, // Set a specific width constraint
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      16), // Add some horizontal padding
                                              margin: EdgeInsets.symmetric(
                                                  vertical: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(
                                                    12), // Rounded corners for the container
                                              ),
                                              child: DropdownButton<String>(
                                                isExpanded:
                                                    true, // Ensure the dropdown expands to fit the container width
                                                value: selectedStrategies[
                                                                clientId] ==
                                                            null ||
                                                        !(clientStrategyMap[
                                                                    clientId] ??
                                                                [])
                                                            .contains(
                                                                selectedStrategies[
                                                                    clientId])
                                                    ? clientStrategyMap[
                                                            clientId]![
                                                        0] // Default to first item if none selected
                                                    : selectedStrategies[
                                                        clientId],
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedStrategies[
                                                        clientId] = newValue!;
                                                  });
                                                },
                                                items: [
                                                  ...(clientStrategyMap[
                                                              clientId] ??
                                                          [])
                                                      .map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                        (strategy) =>
                                                            DropdownMenuItem<
                                                                String>(
                                                          value: strategy,
                                                          child: Text(
                                                            strategy,
                                                            style: TextStyle(
                                                                fontSize:
                                                                    16, // Text size for the dropdown
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500, // Medium weight for text
                                                                color: themeManager
                                                                            .themeMode ==
                                                                        ThemeMode
                                                                            .dark
                                                                    ? AppColors
                                                                        .lightPrimary
                                                                    : AppColors
                                                                        .darkPrimary),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            child:
                                                Text("No strategies available"),
                                          ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: allSheetData
                          .where((sheet) =>
                              sheet["UserId"] == clientId &&
                              sheet["strategyName"] ==
                                  selectedStrategies[clientId])
                          .map((filteredSheet) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10),
                          child: MultiCalendar(
                            index2: index,
                            allSheetData: allSheetData,
                            selectedStrategy:
                                selectedStrategies[clientId] ?? "",
                            clientId: clientId,
                            updatedAllSheetData:
                                updatedAllSheetData, // Now passing the data directly
                          ),
                        );
                      }).toList(),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountItem(String label, String value) {
    print("📝 $label: $value"); // Logging each item with emoji
    return Padding(
      padding: EdgeInsets.only(top: 5, left: 20, right: 20),
      child: Row(
        children: [
          Text(
            "$label : ",
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _statItem(String title, Widget content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
        content,
      ],
    );
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose of the controller before calling super.dispose()
    super.dispose();
  }
}

class SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(),
    );
  }
}
