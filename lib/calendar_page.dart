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
      appBar: AppBar(title: Text('Calendar')),
      body: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 1, 1),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (widget.takenMedicines.contains(day)) {
              return Center(
                  child: Icon(Icons.check_circle, color: Colors.green));
            } else {
              return Center(child: Icon(Icons.cancel, color: Colors.red));
            }
          },
        ),
      ),
    );
  }
}
