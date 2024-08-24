import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class TrackMedicinePage extends StatefulWidget {
  final List<DateTime> takenMedicines;

  TrackMedicinePage({required this.takenMedicines});

  @override
  _TrackMedicinePageState createState() => _TrackMedicinePageState();
}

class _TrackMedicinePageState extends State<TrackMedicinePage> {
  List<String> medicines = [];
  List<bool> takenMedicineToday = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadMedicineData();
    resetAtMidnight();
  }

  void addMedicine(String medicine) {
    setState(() {
      medicines.add(medicine);
      takenMedicineToday.add(false);
    });
    saveMedicineData();
  }

  void removeMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
      takenMedicineToday.removeAt(index);
    });
    saveMedicineData();
  }

  void toggleMedicineCheck(int index) {
    setState(() {
      takenMedicineToday[index] = !takenMedicineToday[index];
    });
    saveMedicineData();
  }

  void confirmMedicineTaken() {
    if (takenMedicineToday.every((taken) => taken)) {
      setState(() {
        widget.takenMedicines.add(selectedDate);
      });
    }
  }

  void saveMedicineData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicines', jsonEncode(medicines));
    await prefs.setString('takenMedicineToday', jsonEncode(takenMedicineToday));
  }

  void loadMedicineData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMedicines = prefs.getString('medicines');
    String? savedTakenStatus = prefs.getString('takenMedicineToday');

    if (savedMedicines != null && savedTakenStatus != null) {
      setState(() {
        medicines = List<String>.from(jsonDecode(savedMedicines));
        takenMedicineToday = List<bool>.from(jsonDecode(savedTakenStatus));
      });
    }
  }

  void resetAtMidnight() async {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);

    Duration timeUntilMidnight = nextMidnight.difference(now);
    await Future.delayed(timeUntilMidnight);

    setState(() {
      takenMedicineToday = List<bool>.filled(medicines.length, false);
    });

    saveMedicineData();

    // Restart the reset process for the next midnight
    resetAtMidnight();
  }

  String getFormattedDate() {
    return DateFormat('EEEE, MMMM d')
        .format(selectedDate); // e.g., Monday, August 23
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getFormattedDate()),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddMedicineDialog(
                  onAddMedicine: (medicine) {
                    addMedicine(medicine);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(medicines[index]),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    removeMedicine(index);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(medicines[index]),
                    trailing: Checkbox(
                      value: takenMedicineToday[index],
                      onChanged: (value) {
                        toggleMedicineCheck(index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                saveMedicineData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Your medicines have been saved!'),
                ));
              },
              child: Text('Save My Meds'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Full-width button
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddMedicineDialog extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final Function(String) onAddMedicine;

  AddMedicineDialog({required this.onAddMedicine});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Medicine'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Medicine Name'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onAddMedicine(_controller.text);
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
