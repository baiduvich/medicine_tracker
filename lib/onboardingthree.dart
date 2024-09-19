import 'package:flutter/material.dart';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:adapty_ui_flutter/adapty_ui_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart'; // For handling URLs
import 'package:video_player/video_player.dart';
import 'home_page.dart';

class OnboardingThree extends StatefulWidget {
  @override
  _OnboardingThreeState createState() => _OnboardingThreeState();
}

class _OnboardingThreeState extends State<OnboardingThree>
    with AdaptyUIObserver {
  late VideoPlayerController _controller;
  final adapty = Adapty();

  @override
  void initState() {
    super.initState();
    // Initialize the video controller with the video asset (video3)
    _controller = VideoPlayerController.asset('assets/videos/video3.mov')
      ..initialize().then((_) {
        setState(() {}); // Update the state once the video is initialized
        _controller.play(); // Play the video automatically
        _controller.setLooping(true); // Loop the video
      });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose of the controller when the widget is disposed
    super.dispose();
  }

  Future<void> _showPaywall(BuildContext context) async {
    try {
      print("Fetching paywall...");
      final paywall =
          await adapty.getPaywall(placementId: "medicine_placementpro");

      if (paywall != null) {
        print("Paywall fetched successfully: ${paywall.variationId}");

        // Add observer to listen for events
        AdaptyUI().addObserver(this);

        final view = await AdaptyUI().createPaywallView(
            paywall: paywall, locale: "en", preloadProducts: true);
        print("Paywall view created successfully, presenting paywall...");
        await view.present();
      } else {
        print("Failed to fetch paywall: Paywall is null");
      }
    } catch (e) {
      print("An error occurred: $e");
      if (e is AdaptyError) {
        print(
            "Adapty error code: ${e.code}, message: ${e.message}, detail: ${e.detail}");
      } else {
        print("Unknown error: $e");
      }
    }
  }

  @override
  void paywallViewDidPerformAction(AdaptyUIView view, AdaptyUIAction action) {
    if (action.type == AdaptyUIActionType.close) {
      view.dismiss(); // Dismiss the paywall
      print("Paywall dismissed, navigating to HomePageWidget...");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (action.type == AdaptyUIActionType.openUrl) {
      final urlString = action.value;
      if (urlString != null) {
        _launchURL(urlString); // Launch the URL
      }
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (await canLaunchUrlString(urlString)) {
      await launchUrlString(urlString);
    } else {
      print("Could not launch $urlString");
    }
  }

  @override
  void paywallViewDidFinishPurchase(
      AdaptyUIView view, AdaptyPaywallProduct product, AdaptyProfile profile) {
    print("Purchase successful for product: ${product.vendorProductId}");
    view.dismiss(); // Dismiss the paywall
    print("Navigating to HomePageWidget after successful purchase...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        // Make the content scrollable
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 80), // Add some spacing from the top
              _controller.value.isInitialized
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10.0), // Rounded corners
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Border color
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                          border: Border.all(
                            color: Colors.yellow, // Yellow border
                            width: 10, // Border thickness
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.8, // 80% of the available width
                          child: AspectRatio(
                            aspectRatio: _controller
                                .value.aspectRatio, // Maintain aspect ratio
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: screenWidth * 0.8,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
              SizedBox(height: 20),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'TRACK ', // Highlighted text
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.yellow, // Yellow color for 'UNLIMITED'
                    fontWeight: FontWeight.bold, // Make text bold
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Your Medicines History...!',
                      style: TextStyle(
                        color: Colors.white, // Normal text color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _showPaywall(
                      context); // Show the paywall when the user clicks Finish
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red, // Button text color
                  backgroundColor: Colors.white, // Button background color
                ),
                child: Text(
                  'Start!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, // Make button text bold
                  ),
                ),
              ),
              SizedBox(height: 40), // Add some spacing to the bottom
            ],
          ),
        ),
      ),
    );
  }
}
