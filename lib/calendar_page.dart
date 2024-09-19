import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  Map<DateTime, List<Map<String, dynamic>>> medicineLog = {};

  CalendarPage({required this.medicineLog});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> medicinesForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    loadMedicineLog(); // Load the entire medicine log from storage
    loadMedicinesForSelectedDay(
        selectedDate); // Load medicines for today's date on init
  }

  // Load the medicine log from SharedPreferences
  void loadMedicineLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedLog = prefs.getString('medicineLog');

    if (encodedLog != null) {
      setState(() {
        Map<String, dynamic> decodedLog = jsonDecode(encodedLog);
        widget.medicineLog = decodedLog.map((key, value) {
          return MapEntry(
            DateTime.parse(key),
            List<Map<String, dynamic>>.from(value).map((medicine) {
              return {
                'name': medicine['name'],
                'time': medicine['time'],
                'taken': medicine['taken'] ??
                    false, // Default to false if not present
              };
            }).toList(),
          );
        });
      });
      print("Loaded medicine log: ${widget.medicineLog}");
    } else {
      print("No medicine log found.");
    }
  }

  // Load medicines for a specific day
  void loadMedicinesForSelectedDay(DateTime day) {
    setState(() {
      // Normalize day to have no time component
      DateTime normalizedDay = DateTime(day.year, day.month, day.day);
      medicinesForSelectedDay = widget.medicineLog[normalizedDay] ?? [];
      print(
          "Medicines for selected day ($normalizedDay): $medicinesForSelectedDay");
    });
  }

  // This function checks if all medicines are taken for the selected day
  bool allMedicinesTakenForDay(DateTime day) {
    // Normalize day to have no time component
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    List<Map<String, dynamic>> medicines =
        widget.medicineLog[normalizedDay] ?? [];
    print("Checking if all medicines are taken for $normalizedDay: $medicines");
    if (medicines.isEmpty) {
      print("No medicines found for $normalizedDay");
      return false;
    }

    bool allTaken = medicines.every((medicine) => medicine['taken'] == true);
    print("All medicines taken for $normalizedDay: $allTaken");
    return allTaken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Calendar')),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              focusedDay: selectedDate,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 1, 1),
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  selectedDate = selectedDay;
                  loadMedicinesForSelectedDay(selectedDay);
                });
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(
                  color: Colors.black, // Set default text color to black
                ),
                weekendTextStyle: TextStyle(
                  color: Colors.black, // Ensure weekend dates are black
                ),
                holidayTextStyle: TextStyle(
                  color: Colors.black, // Ensure holiday dates are black
                ),
                todayTextStyle: TextStyle(
                  color: Colors.white, // Set today's text color to white
                ),
                todayDecoration: const BoxDecoration(
                  color: Colors.red, // Red background for today
                  shape: BoxShape.circle, // Circle for today
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white, // Set selected day text color to white
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.purple, // Purple background for selected day
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green, // Set marker color
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, focusedDay) {
                  bool allMedicinesTaken = allMedicinesTakenForDay(day);

                  print(
                      "Marker for $day: ${allMedicinesTaken ? 'Green' : 'Red'}");

                  if (allMedicinesTaken) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16.0,
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 16.0,
                      ),
                    );
                  }
                },
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ),

          // Display medicines for the selected day
          Expanded(
            child: medicinesForSelectedDay.isEmpty
                ? Center(
                    child: Text('No medicines for this day'),
                  )
                : ListView.builder(
                    itemCount: medicinesForSelectedDay.length,
                    itemBuilder: (context, index) {
                      var medicine = medicinesForSelectedDay[index];
                      return ListTile(
                        title: Text(medicine['name']),
                        trailing: Checkbox(
                          value: medicine['taken'],
                          onChanged: (value) {
                            setState(() {
                              medicine['taken'] = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
