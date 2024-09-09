import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final List<DateTime> takenMedicines;

  CalendarPage({required this.takenMedicines});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0), // Margin around the box
          padding: const EdgeInsets.all(8.0), // Padding inside the box
          decoration: BoxDecoration(
            color: Colors.white, // White background for the box
            borderRadius: BorderRadius.circular(12), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4), // Shadow positioning
              ),
            ],
          ),
          // Use a SizedBox with a fixed height to better control the layout
          child: SizedBox(
            height: 400, // Set an appropriate height for the calendar
            child: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 1, 1),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false, // Hide outside days
                defaultTextStyle:
                    const TextStyle(color: Colors.red), // Red text for dates
                todayDecoration: const BoxDecoration(
                  color: Colors.red, // Red background for today
                  shape: BoxShape.circle, // Circle for today
                ),
                selectedDecoration: BoxDecoration(
                  color:
                      Colors.red[900], // Dark red background for selected day
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // Hide format button
                titleCentered: true, // Center the title
                titleTextStyle: TextStyle(
                    color: Colors.red, fontSize: 18), // Red text for title
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (widget.takenMedicines.contains(day)) {
                    return const Center(
                      child: Icon(Icons.check_circle,
                          color:
                              Colors.green), // Green check for taken medicine
                    );
                  } else {
                    return const Center(
                      child: Icon(Icons.cancel,
                          color:
                              Colors.red), // Red cancel for not taken medicine
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
