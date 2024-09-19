import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:adapty_ui_flutter/adapty_ui_flutter.dart';

class TrackMedicinePage extends StatefulWidget {
  final Map<DateTime, List<Map<String, dynamic>>> medicineLog;

  TrackMedicinePage({required this.medicineLog});

  @override
  _TrackMedicinePageState createState() => _TrackMedicinePageState();
}

class _TrackMedicinePageState extends State<TrackMedicinePage>
    with AdaptyUIObserver {
  List<Map<String, dynamic>> medicines = [];
  List<bool> takenMedicineToday = [];
  bool hasLifetimeAccess = false;
  final adapty = Adapty();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    loadMedicineData(); // Load saved medicines if they exist
    resetAtMidnight();
    _checkFirstTimeUser();
    _checkUserAccess();
  }

  @override
  void paywallViewDidCancelPurchase(
      AdaptyUIView view, AdaptyPaywallProduct product) {
    print("Purchase cancelled for product: ${product.vendorProductId}");
  }

  @override
  void paywallViewDidFailRendering(AdaptyUIView view, AdaptyError error) {
    print("Rendering failed: ${error.message}");
  }

  @override
  void paywallViewDidFinishRestore(AdaptyUIView view, AdaptyProfile profile) {
    print("Restore finished, profile: $profile");
  }

  // Automatically save whenever a new medicine is added or modified
  void addMedicine(String medicine, TimeOfDay time) {
    print("Adding medicine: $medicine at ${time.format(context)}");
    int minutesSinceMidnight = time.hour * 60 + time.minute;
    setState(() {
      medicines.add(
          {'name': medicine, 'time': minutesSinceMidnight, 'taken': false});
      takenMedicineToday.add(false);
      scheduleNotification(medicine, time);
      saveMedicineData(); // Auto-save here
    });
  }

  Future<void> _checkUserAccess() async {
    try {
      final profile = await adapty.getProfile();
      setState(() {
        hasLifetimeAccess = profile?.accessLevels['premium']?.isActive ?? false;
      });
    } catch (e) {
      print("An error occurred while fetching user access: $e");
    }
  }

  Future<void> _showPaywall(BuildContext context) async {
    try {
      final paywall =
          await adapty.getPaywall(placementId: "medicine_placementpro");

      if (paywall != null) {
        AdaptyUI().addObserver(this);
        final view = await AdaptyUI().createPaywallView(
            paywall: paywall, locale: "en", preloadProducts: true);
        await view.present();
      } else {
        print("Failed to fetch paywall: Paywall is null");
      }
    } catch (e) {
      print("An error occurred: $e");
    }
  }

  // Remove a medicine and auto-save
  void removeMedicine(int index) {
    print("Removing medicine: ${medicines[index]['name']}");
    setState(() {
      medicines.removeAt(index);
      takenMedicineToday.removeAt(index);
      saveMedicineData(); // Auto-save after removing
    });
  }

  TimeOfDay timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  // Toggle medicine check and auto-save
  void toggleMedicineCheck(int index) {
    if (index < 0 || index >= medicines.length) {
      print("Invalid index accessed in toggleMedicineCheck: $index");
      return;
    }

    print(
        "Toggling medicine: ${medicines[index]['name']} - ${takenMedicineToday[index] ? 'Unchecked' : 'Checked'}");
    setState(() {
      takenMedicineToday[index] = !takenMedicineToday[index];
      medicines[index]['taken'] = takenMedicineToday[index];
      saveMedicineData(); // Auto-save after check/uncheck
    });

    // Normalize the date to remove time component
    DateTime normalizedDate = DateTime.now();
    DateTime onlyDate =
        DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day);

    // Update medicine log and save
    widget.medicineLog[onlyDate] = medicines;
    saveMedicineLog();
  }

  void saveMedicineLog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> encodedLog = widget.medicineLog.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });
    prefs.setString('medicineLog', jsonEncode(encodedLog));
    print("Medicine log saved.");
  }

  // Save medicine data for the default list (used every day)
  void saveMedicineData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> medicinesForDay = {
      'medicines': medicines,
      'takenMedicines': takenMedicineToday
    };
    prefs.setString('dailyMedicines', jsonEncode(medicinesForDay));
    print("Medicine data saved.");
    print("Saved Data: ${jsonEncode(medicinesForDay)}");
  }

  // Load saved medicines for the default list (used every day)
  void loadMedicineData() async {
    print("Loading medicine data...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('dailyMedicines');

    if (savedData != null) {
      setState(() {
        Map<String, dynamic> data = jsonDecode(savedData);
        medicines = List<Map<String, dynamic>>.from(data['medicines']);
        takenMedicineToday = List<bool>.from(data['takenMedicines']);
      });
      print("Loaded medicines: ${medicines.length}");
    } else {
      print("No saved medicine data found.");
    }
  }

  // Reset the medicine checkboxes at midnight
  void resetAtMidnight() async {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);
    print("Time until midnight reset: $timeUntilMidnight");

    await Future.delayed(timeUntilMidnight);
    setState(() {
      takenMedicineToday = List<bool>.filled(medicines.length, false);
      for (var i = 0; i < medicines.length; i++) {
        medicines[i]['taken'] = false;
      }
    });
    saveMedicineData();
    resetAtMidnight(); // Restart the reset process for the next midnight
  }

  // First-time user popup
  void _checkFirstTimeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('isFirstTime');

    if (isFirstTime == null || isFirstTime == true) {
      Future.delayed(Duration.zero, () => _showFirstTimeDialog());
      await prefs.setBool('isFirstTime', false);
    }
  }

  // First-time user dialog
  void _showFirstTimeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Welcome to Medicine Tracker!',
            style: TextStyle(color: Colors.red),
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.red, fontSize: 16),
              children: [
                TextSpan(text: 'Click the '),
                TextSpan(
                  text: '+',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                style: TextStyle(color: Colors.red),
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

  // Modify the showTimePickerForMedicine to accept a format parameter
  void showTimePickerForMedicine(
      String medicineName, bool is24HourFormat) async {
    print(
        "Showing time picker for $medicineName with ${is24HourFormat ? '24-hour' : 'AM/PM'} format");

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'When do you want to be reminded?', // Updated help text
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: is24HourFormat, // Use the chosen format
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      print("Time selected: ${selectedTime.format(context)} for $medicineName");

      // Here you check if the user has paid
      if (hasLifetimeAccess) {
        // If the user has paid, proceed with adding the medicine
        addMedicine(medicineName, selectedTime);
      } else {
        // If the user hasn't paid, show the paywall
        await _showPaywall(context); // This is where you show the paywall
      }
    } else {
      print("No time selected for $medicineName.");
    }
  }

  String getFormattedDate() {
    return DateFormat('EEEE, MMMM d')
        .format(DateTime.now()); // e.g., Monday, August 23
  }

  // Show format selection dialog and schedule reminder
  void _showFormatSelectionAndTimePicker(String medicineName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Please choose your hour format for daily reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('24-Hour Format'),
                onTap: () {
                  Navigator.pop(context);
                  showTimePickerForMedicine(medicineName, true);
                },
              ),
              ListTile(
                title: Text('AM/PM Format'),
                onTap: () {
                  Navigator.pop(context);
                  showTimePickerForMedicine(medicineName, false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Schedule notification
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

    final now = DateTime.now();
    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    DateTime adjustedScheduledDate = scheduledDate;
    if (scheduledDate.isBefore(now)) {
      adjustedScheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        medicines.indexWhere((medicine) => medicine['name'] == medicineName),
        'Time to take your medicine!',
        'It\'s time to take $medicineName',
        tz.TZDateTime.from(adjustedScheduledDate, tz.local),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
      print("Notification for $medicineName successfully scheduled.");
    } catch (e) {
      print("Error scheduling notification: $e");
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
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddMedicineDialog(
                  onAddMedicine: (medicine) {
                    Navigator.pop(context);
                    _showFormatSelectionAndTimePicker(medicine);
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
                if (index < 0 || index >= medicines.length) {
                  print("Invalid index accessed in ListView.builder: $index");
                  return Container(); // Return an empty container if index is out of bounds
                }
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
      backgroundColor: Colors.white,
      title: Text(
        'Add Medicine',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Medicine Name',
          hintStyle: TextStyle(color: Colors.red),
        ),
        style: TextStyle(color: Colors.red),
      ),
      actions: [
        TextButton(
          onPressed: () {
            String medicineName = _controller.text.trim();
            if (medicineName.isNotEmpty) {
              onAddMedicine(medicineName);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Please enter a medicine name.'),
              ));
            }
          },
          child: Text(
            'Add',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
