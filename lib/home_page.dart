import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'track_medicine_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DateTime> takenMedicines = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0), // Adds some spacing
              child: Text(
                'Add your medicine below and keep track of everything in the calendar.',
                textAlign: TextAlign.center, // Center the text
                style: TextStyle(
                  color: Colors.white, // White text
                  fontSize: 18, // Slightly bigger text
                  fontWeight: FontWeight.bold, // Make text bold
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CalendarPage(takenMedicines: takenMedicines),
                  ),
                );
              },
              child: const Text(
                'Calendar',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Make button text bold
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedList = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrackMedicinePage(takenMedicines: takenMedicines),
                  ),
                );
                if (updatedList != null) {
                  setState(() {
                    takenMedicines = updatedList;
                  });
                }
              },
              child: const Text(
                'Track Medicine',
                style: TextStyle(
                  fontWeight: FontWeight.bold, // Make button text bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
