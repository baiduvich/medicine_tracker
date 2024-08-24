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
              child: Text('Calendar'),
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
              child: Text('Track Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}
