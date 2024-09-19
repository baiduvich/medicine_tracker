import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Function to handle the review counter and decide whether to show a dialog
Future<bool> shouldShowReview() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int counter = (prefs.getInt('counter') ?? 0);
  counter++;
  await prefs.setInt('counter', counter);
  return (counter % 3 != 0);
}

// Function to show the first dialog asking if the user likes the app
Future<void> askForReview(BuildContext context) async {
  if (await shouldShowReview()) {
    final InAppReview inAppReview = InAppReview.instance;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Do you like our app?"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showRateAppDialog(context, inAppReview);
              },
              child: Text("Yes"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Function to show the second dialog asking the user to rate the app
void showRateAppDialog(BuildContext context, InAppReview inAppReview) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("A Quick Favor!"),
        content: RichText(
          text: TextSpan(
            text: 'Please, just for ',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: '2 SECONDS, RATE OUR APP!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'You\'ll help us a lot!',
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              inAppReview.requestReview();
            },
            child: Text("Yes"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      );
    },
  );
}

// Function to directly show the in-app review prompt
Future<void> showDirectReview() async {
  if (await shouldShowReview()) {
    final InAppReview inAppReview = InAppReview.instance;
    inAppReview.requestReview();
  }
}
