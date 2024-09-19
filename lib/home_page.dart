import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'track_medicine_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<DateTime, List<Map<String, dynamic>>> medicineLog =
      {}; // Track medicines per date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Add your medicine below and keep track of everything in the calendar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Button to navigate to the CalendarPage
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarPage(
                      medicineLog:
                          medicineLog, // Pass medicineLog to CalendarPage
                    ),
                  ),
                );
              },
              child: const Text(
                'Calendar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Button to navigate to TrackMedicinePage
            ElevatedButton(
              onPressed: () async {
                final updatedLog = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackMedicinePage(
                      medicineLog:
                          medicineLog, // Pass medicineLog to TrackMedicinePage
                    ),
                  ),
                );
                if (updatedLog != null) {
                  setState(() {
                    medicineLog =
                        updatedLog; // Update the medicineLog after returning
                  });
                }
              },
              child: const Text(
                'Track Medicine',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
