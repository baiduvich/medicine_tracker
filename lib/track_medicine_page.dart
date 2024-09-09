import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';

class TrackMedicinePage extends StatefulWidget {
  final List<DateTime> takenMedicines;

  TrackMedicinePage({required this.takenMedicines});

  @override
  _TrackMedicinePageState createState() => _TrackMedicinePageState();
}

class _TrackMedicinePageState extends State<TrackMedicinePage> {
  List<Map<String, dynamic>> medicines = []; // List with name and time
  List<bool> takenMedicineToday = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone data
    print("Timezones initialized!");
    loadMedicineData();
    resetAtMidnight();
    _checkFirstTimeUser(); // Show pop-up for first-time users
  }

  void addMedicine(String medicine, TimeOfDay time) {
    print("Adding medicine: $medicine at ${time.format(context)}");
    int minutesSinceMidnight =
        time.hour * 60 + time.minute; // Store as minutes since midnight
    setState(() {
      medicines.add({'name': medicine, 'time': minutesSinceMidnight});
      takenMedicineToday.add(false);
      scheduleNotification(medicine, time);
    });
    saveMedicineData();
  }

  void removeMedicine(int index) {
    print("Removing medicine: ${medicines[index]['name']}");
    setState(() {
      medicines.removeAt(index);
      takenMedicineToday.removeAt(index);
    });
    saveMedicineData();
  }

  void toggleMedicineCheck(int index) {
    print(
        "Toggling medicine: ${medicines[index]['name']} - ${takenMedicineToday[index] ? 'Unchecked' : 'Checked'}");
    setState(() {
      takenMedicineToday[index] = !takenMedicineToday[index];
    });
    saveMedicineData();
  }

  void confirmMedicineTaken() {
    if (takenMedicineToday.every((taken) => taken)) {
      print("All medicines taken on $selectedDate");
      setState(() {
        widget.takenMedicines.add(selectedDate);
      });
    }
  }

  void saveMedicineData() async {
    print("Saving medicine data...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicines', jsonEncode(medicines));
    await prefs.setString('takenMedicineToday', jsonEncode(takenMedicineToday));
    print("Medicine data saved!");
  }

  void loadMedicineData() async {
    print("Loading medicine data...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedMedicines = prefs.getString('medicines');
    String? savedTakenStatus = prefs.getString('takenMedicineToday');

    if (savedMedicines != null && savedTakenStatus != null) {
      setState(() {
        medicines = List<Map<String, dynamic>>.from(jsonDecode(savedMedicines));
        takenMedicineToday = List<bool>.from(jsonDecode(savedTakenStatus));
      });
      print("Loaded medicines: ${medicines.length}");
    } else {
      print("No saved medicine data found.");
    }
  }

  void resetAtMidnight() async {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);

    Duration timeUntilMidnight = nextMidnight.difference(now);
    print("Time until midnight reset: $timeUntilMidnight");

    await Future.delayed(timeUntilMidnight);

    setState(() {
      takenMedicineToday = List<bool>.filled(medicines.length, false);
    });

    saveMedicineData();

    // Restart the reset process for the next midnight
    print("Reset at midnight complete.");
    resetAtMidnight();
  }

  void _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('isFirstTime');

    if (isFirstTime == null || isFirstTime == true) {
      // Show the dialog explaining how to add a medicine
      Future.delayed(Duration.zero, () => _showFirstTimeDialog());
      // Set isFirstTime to false so it doesn't show again
      await prefs.setBool('isFirstTime', false);
    }
  }

  void _showFirstTimeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Set background to white
          title: Text(
            'Welcome to Medicine Tracker!',
            style: TextStyle(color: Colors.red), // Set title text color to red
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 16), // Red text color for content
              children: [
                TextSpan(text: 'Click the '),
                TextSpan(
                  text: '+',
                  style: TextStyle(
                      fontWeight: FontWeight.bold), // Make "+" text bold
                ),
                TextSpan(
                    text: ' button above right to add a medicine to track.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Got it!',
                style: TextStyle(color: Colors.red), // Red text for the button
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  String getFormattedDate() {
    return DateFormat('EEEE, MMMM d')
        .format(selectedDate); // e.g., Monday, August 23
  }

  // Convert the stored minutes to TimeOfDay
  TimeOfDay timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  void scheduleNotification(String medicineName, TimeOfDay time) async {
    print(
        "Scheduling notification for $medicineName at ${time.format(context)}");

    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'med_reminder_channel',
      'Medicine Reminder',
      channelDescription: 'Channel for Medicine Reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Medicine Reminder',
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Get current device time
    final now = DateTime.now();
    print("Current time: $now");

    // Create a DateTime for the scheduled notification based on TimeOfDay
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for the next day
    DateTime adjustedScheduledDate = scheduledDate;
    if (scheduledDate.isBefore(now)) {
      print("Scheduled time is in the past, adjusting to next day.");
      adjustedScheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("Notification scheduled for: $adjustedScheduledDate");

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        medicines.indexWhere((medicine) => medicine['name'] == medicineName),
        'Time to take your medicine!',
        'It\'s time to take $medicineName',
        tz.TZDateTime.from(adjustedScheduledDate, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time, // Schedule daily
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      print("Notification for $medicineName successfully scheduled.");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  // Show time picker when adding medicine
  void showTimePickerForMedicine(String medicineName) async {
    print("Showing time picker for $medicineName");

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red, // Red color for the header
              onSurface: Colors.red, // Red color for the text
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white, // White background
              hourMinuteShape: const RoundedRectangleBorder(
                // Modify hour and minute shape
                borderRadius: BorderRadius.all(Radius.circular(8)),
                side: BorderSide(color: Colors.red),
              ),
              hourMinuteTextColor: MaterialStateColor.resolveWith(
                (states) =>
                    Colors.white, // Set text color for hour/minutes to white
              ),
              dialHandColor: Colors.red, // Red for the dial hand
              dialTextColor: MaterialStateColor.resolveWith(
                (states) => Colors.red, // Red for dial numbers
              ),
              hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? Colors.red
                      : Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      print("Time selected: ${selectedTime.format(context)} for $medicineName");
      addMedicine(medicineName, selectedTime);
    } else {
      print("No time selected for $medicineName.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getFormattedDate()),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              size: 30, // Increase the size to make it more prominent
              color: Colors.white, // Ensure the color matches the theme
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddMedicineDialog(
                  onAddMedicine: (medicine) {
                    Navigator.pop(context);
                    showTimePickerForMedicine(medicine);
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
                var medicine = medicines[index];
                TimeOfDay time = timeFromMinutes(medicine['time']);
                return Dismissible(
                  key: Key(medicine['name']),
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
                    title: Text(medicine['name']),
                    subtitle: Text('Reminder at ${time.format(context)}'),
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
      backgroundColor: Colors.white, // Set background to white
      title: Text(
        'Add Medicine',
        style: TextStyle(
          color: Colors.red, // Red title text
          fontWeight: FontWeight.bold, // Make title bold
        ),
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Medicine Name',
          hintStyle: TextStyle(color: Colors.red), // Red hint text
        ),
        style: TextStyle(color: Colors.red), // Red input text
      ),
      actions: [
        TextButton(
          onPressed: () {
            onAddMedicine(_controller.text);
          },
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.red, // Red button text
              fontWeight: FontWeight.bold, // Make button text bold
            ),
          ),
        ),
      ],
    );
  }
}
