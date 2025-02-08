import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

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

  @override
  void initState() {
    super.initState();
    selectedMonths =
        List.generate(widget.allSheetData.length, (_) => DateTime.now());
    selectedYears =
        List.generate(widget.allSheetData.length, (_) => DateTime.now().year);
  }

  // Generate a map of date -> P&L
  // Convert sheetData into a map of date -> P&L
  Map<String, double> generatePnlMap(List<dynamic> sheetData) {
    final Map<String, double> pnlMap = {};

    for (var entry in sheetData) {
      final date = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(entry[3])); // Assuming date is at index 3
      var pnl = entry[10]; // P&L value is at index 9

      // Convert P&L to double if it's a String
      if (pnl is String) {
        pnl = double.tryParse(pnl) ??
            0.0; // Try parsing to double, default to 0.0 if it fails
      }

      pnlMap[date] = pnl;
    }

    return pnlMap;
  }

  void handleMonthChange(int sheetIndex, int month) {
    setState(() {
      selectedMonths[sheetIndex] =
          DateTime(selectedMonths[sheetIndex].year, month + 1, 1);
    });
  }

  void handleYearChange(int sheetIndex, int year) {
    setState(() {
      selectedYears[sheetIndex] = year;
      selectedMonths[sheetIndex] =
          DateTime(year, selectedMonths[sheetIndex].month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.allSheetData
          .where((sheet) => sheet['UserId'] == widget.clientId)
          .map((filteredSheet) {
        final sheetName = filteredSheet['sheetName'];
        final pnlByDate = generatePnlMap(
            filteredSheet['sheetData']); // Get P&L map for the sheet

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

        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetName ??
                    'Spreadsheet ${widget.allSheetData.indexOf(filteredSheet) + 1}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Month Dropdown
              DropdownButton<int>(
                value: selectedMonth.month - 1,
                onChanged: (newMonth) {
                  if (newMonth != null) {
                    handleMonthChange(
                        widget.allSheetData.indexOf(filteredSheet), newMonth);
                  }
                },
                items: List.generate(12, (index) {
                  final monthName = DateFormat('MMMM')
                      .format(DateTime(selectedMonth.year, index + 1, 1));
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(monthName),
                  );
                }),
              ),
              // Year Dropdown
              DropdownButton<int>(
                value: selectedYear,
                onChanged: (newYear) {
                  if (newYear != null) {
                    handleYearChange(
                        widget.allSheetData.indexOf(filteredSheet), newYear);
                  }
                },
                items: List.generate(10, (index) {
                  final year = DateTime.now().year - (9 - index);
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
              ),
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, childAspectRatio: 1),
                shrinkWrap: true,
                itemCount: days.length + 7,
                itemBuilder: (context, index) {
                  if (index < 7) {
                    final dayOfWeek = [
                      'Sun',
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat'
                    ][index];
                    return Center(
                        child: Text(dayOfWeek,
                            style: TextStyle(fontWeight: FontWeight.bold)));
                  }

                  final day = days[index - 7];
                  final dateKey = DateFormat('yyyy-MM-dd').format(day);
                  final pnl = pnlByDate[dateKey]; // Get P&L for the day

                  final isCurrentMonth = day.month == selectedMonth.month;

                  return GestureDetector(
                    onTap: () {
                      print('Date clicked: $dateKey');
                      if (pnl != null) {
                        print('P&L for $dateKey: $pnl');
                      } else {
                        print('No P&L data available for $dateKey');
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: pnl != null
                            ? (pnl > 0
                                ? Colors.green
                                : pnl < 0
                                    ? Colors.red
                                    : Colors.grey[200])
                            : Colors.grey[200],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                  color: isCurrentMonth
                                      ? Colors.black
                                      : Colors.grey),
                            ),
                            if (pnl != null)
                              Text(
                                pnl.toStringAsFixed(2),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
